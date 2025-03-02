use std::{collections::HashMap, process::Command};
use std::path::PathBuf;
use extism::{host_fn, Function, Manifest, Plugin, Wasm, PTR};
use flutter_rust_bridge::frb;
use serde::{Serialize, Deserialize};
use serde_json;
use anyhow::{Result, anyhow};
use std::env;
use regex::Regex;
use chrono;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PluginItem {
    pub name: String,
    pub description: String,
    pub icon: String,
}

#[derive(Debug, Clone)]
struct CliConfig {
    enabled: bool,
    plugin_name: String,
    data_dir_path: String,
}

// We can't derive Hash for HashMap, so we'll store config as a sorted Vec of tuples
#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub struct PluginIdentifier {
    name: String,
    config: Vec<(String, String)>,
}

impl PluginIdentifier {
    fn from_map(name: String, config: &Vec<(String, String)>) -> Self {
        let mut config_vec = config.clone();
        config_vec.sort_by(|a, b| a.0.cmp(&b.0));
        Self {
            name,
            config: config_vec,
        }
    }
}

#[derive(Debug)]
pub struct PluginConfig {
    pub wasm_path: String,
    pub allowed_paths: Vec<String>,
    pub allowed_hosts: Vec<String>,
    pub enable_wasi: bool,
    pub cli: bool,
    pub config: Vec<(String, String)>,
}

#[frb(sync)]
#[frb(opaque)]
pub struct PluginManager {
    plugins: HashMap<PluginIdentifier, Plugin>,
    cache: HashMap<PluginIdentifier, Vec<PluginItem>>,
}

host_fn!(add_newline(_user_data: (); a: String) -> String { 
    Ok(a + "\n") 
});

host_fn!(cli_run(config: CliConfig; command: String, args: String) -> Result<String> {
    let config_ref = config.get()?;
    let config_guard = config_ref.lock().unwrap();
    if !config_guard.enabled {
        return Ok(format!("[plugin:{}] [cli_run] CLI functionality is disabled in the manifest", config_guard.plugin_name));
    }
    
    let args: Vec<String> = serde_json::from_str(&args)
        .map_err(|e| anyhow!("Failed to parse args as JSON array: {}", e))?;

    println!("[{}] [plugin:{}] [cli_run] Command: {} {:?}", 
        chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
        config_guard.plugin_name,
        command,
        args
    );
    
    let command_path = if command.starts_with("/data/") {
        // If path starts with /data/, resolve it relative to data_dir_path
        let relative_path = command.strip_prefix("/data/").unwrap();
        format!("{}/{}", config_guard.data_dir_path, relative_path)
    } else {
        command
    };

    let output = Command::new(command_path)
        .args(args)
        .output()
        .map_err(|e| anyhow!("Failed to execute command: {}", e))?;

    if output.status.success() {
        String::from_utf8(output.stdout)
            .map_err(|e| anyhow!("Invalid UTF-8 output: {}", e))
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        Err(anyhow!("Command failed: {}", stderr))
    }
});

impl PluginManager {
    pub fn new() -> Self {
        unsafe { extism::sdk::extism_log_file("stdout\0".as_ptr() as *const i8, "info\0".as_ptr() as *const i8); }
        Self {
            plugins: HashMap::new(),
            cache: HashMap::new(),
        }
    }

    pub fn init_plugin(
        &mut self,
        name: String,
        plugin_config: PluginConfig,
        data_dir_path: String,
    ) -> Result<Vec<PluginItem>> {
        let identifier = PluginIdentifier::from_map(name.clone(), &plugin_config.config);

        // Check if plugin is already initialized and return cached items if available
        if let Some(cached_items) = self.cache.get(&identifier) {
            return Ok(cached_items.clone());
        }

        // Create manifest with proper permissions
        let wasm = Wasm::file(&plugin_config.wasm_path);
        let manifest = Manifest::new([wasm])
            .with_allowed_paths(
                plugin_config.allowed_paths.iter()
                    .map(|p| expand_env_vars(p))
            ).with_allowed_path(data_dir_path.clone(), PathBuf::from("data")) // allow access to <plugin_path>/data
            .with_allowed_hosts(plugin_config.allowed_hosts.iter().cloned())
            .with_config(plugin_config.config.iter().cloned())
            .with_config_key("platform", std::env::consts::OS); // add platform key to config - "linux" "windows" "macos"

        let cli_config = CliConfig {
            enabled: plugin_config.cli,
            plugin_name: name.clone(),
            data_dir_path: data_dir_path.clone(),
        };

        let host_function = Function::new(
            "cli_run", 
            [PTR, PTR], 
            [PTR], 
            extism::UserData::new(cli_config), 
            cli_run
        );

        // Create plugin with WASI enabled if configured
        let mut plugin = Plugin::new(&manifest, [host_function], plugin_config.enable_wasi)?;

        // Call init function
        let result = plugin.call::<(), String>("init", ())?;
        let items: Option<Vec<PluginItem>> = if result.is_empty() {
            None
        } else {
            Some(serde_json::from_str(&result)?)
        };

        // Store plugin
        self.plugins.insert(identifier.clone(), plugin);

        // Cache results if available
        if let Some(items) = items.clone() {
            self.cache.insert(identifier, items);
        }

        Ok(items.unwrap_or_default())
    }

    pub fn filter_plugin(
        &mut self,
        name: String,
        config: Vec<(String, String)>,
        query: String,
    ) -> Result<Vec<PluginItem>> {
        let identifier = PluginIdentifier::from_map(name, &config);

        let plugin = self.plugins.get_mut(&identifier)
            .ok_or_else(|| anyhow!("Plugin not found"))?;

        // Call filter function and handle JSON serialization manually
        let result = plugin.call::<String, String>("filter", query.clone())?;
        let items: Option<Vec<PluginItem>> = serde_json::from_str(&result).unwrap_or(None);

        // If filter returns items, use those
        if let Some(items) = items {
            if !items.is_empty() {
                return Ok(items);
            }
        }

        // If no items returned from filter, get cached items and filter them manually
        if let Some(cached_items) = self.cache.get(&identifier) {
            let filtered_items: Vec<PluginItem> = cached_items
                .iter()
                .filter(|item| {
                    item.name.to_lowercase().contains(&query.to_lowercase()) ||
                    item.description.to_lowercase().contains(&query.to_lowercase())
                })
                .cloned()
                .collect();
            return Ok(filtered_items);
        }

        // If no cached items found, return empty vector
        Ok(Vec::new())
    }

    pub fn select(
        &mut self,
        name: String,
        config: Vec<(String, String)>,
        element_name: String,
    ) -> Result<()> {
        let identifier = PluginIdentifier::from_map(name, &config);

        let plugin = self.plugins.get_mut(&identifier)
            .ok_or_else(|| anyhow!("Plugin not found"))?;

        // Call on_select function
        plugin.call::<String, ()>("on_select", element_name)?;

        Ok(())
    }
}

/// Expands environment variables in the provided path.
/// Returns a tuple where:
/// - The first element is the string with environment variables replaced
///   with their corresponding values.
/// - The second element is the string with the '$' characters removed.
///
/// Examples:
/// If HOME is set to "/users/user", then:
///     expand_env_vars("$HOME/.config")
/// returns ("/users/user/.config", "HOME/.config")
///
fn expand_env_vars(path: &str) -> (String, PathBuf) {
    // Regex that matches `$VAR`, where VAR starts with a letter or underscore
    // and is followed by letters, numbers, or underscores.
    let re = Regex::new(r"\$([A-Za-z_][A-Za-z0-9_]*)").unwrap();

    // First part: Replace occurrences of $VAR with their environment variable value.
    // If the variable is not found, the placeholder remains unchanged.
    let expanded = re.replace_all(path, |caps: &regex::Captures| {
        let var_name = &caps[1];
        env::var(var_name).unwrap_or_else(|_| caps[0].to_string())
    });

    // Second part: Create a version with the '$' removed, keeping the variable name.
    let removed_dollar = re.replace_all(path, |caps: &regex::Captures| {
        caps[1].to_string()
    });

    (expanded.to_string(), PathBuf::from(removed_dollar.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_plugin_identifier() {
        let config1 = vec![
            ("key1".to_string(), "value1".to_string()),
            ("key2".to_string(), "value2".to_string()),
        ];

        let config2 = vec![
            ("key2".to_string(), "value2".to_string()),
            ("key1".to_string(), "value1".to_string()),
        ];

        let id1 = PluginIdentifier::from_map("test".to_string(), &config1);
        let id2 = PluginIdentifier::from_map("test".to_string(), &config2);

        assert_eq!(id1, id2);
    }
}
