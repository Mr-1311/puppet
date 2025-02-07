use std::collections::HashMap;
use std::path::PathBuf;
use extism::{Plugin, Manifest, Wasm, Val};
use flutter_rust_bridge::frb;
use serde::{Serialize, Deserialize};
use serde_json;
use anyhow::{Result, anyhow};
use std::env;
use regex::Regex;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PluginItem {
    pub name: String,
    pub description: String,
    pub icon: String,
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
    pub config: Vec<(String, String)>,
}

#[frb(sync)]
#[frb(opaque)]
pub struct PluginManager {
    plugins: HashMap<PluginIdentifier, Plugin>,
    cache: HashMap<PluginIdentifier, Vec<PluginItem>>,
}

impl PluginManager {
    pub fn new() -> Self {
        Self {
            plugins: HashMap::new(),
            cache: HashMap::new(),
        }
    }

    pub fn init_plugin(
        &mut self,
        name: String,
        plugin_config: PluginConfig,
    ) -> Result<Vec<PluginItem>> {
        let identifier = PluginIdentifier::from_map(name.clone(), &plugin_config.config);

        // Create manifest with proper permissions
        let wasm = Wasm::file(&plugin_config.wasm_path);
        let manifest = Manifest::new([wasm])
            .with_allowed_paths(
                plugin_config.allowed_paths.iter()
                    .map(|p| expand_env_vars(p))
            )
            .with_allowed_hosts(plugin_config.allowed_hosts.iter().cloned())
            .with_config(plugin_config.config.iter().cloned());

        // Create plugin with WASI enabled if configured
        let mut plugin = Plugin::new(&manifest, [], plugin_config.enable_wasi)?;

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
        let result = plugin.call::<String, String>("filter", query)?;
        let items: Option<Vec<PluginItem>> = if result.is_empty() {
            None
        } else {
            Some(serde_json::from_str(&result)?)
        };

        // Return cached results if filter returns null
        match items {
            Some(items) => Ok(items),
            None => Ok(self.cache.get(&identifier)
                .cloned()
                .unwrap_or_default()),
        }
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
pub fn expand_env_vars(path: &str) -> (String, PathBuf) {
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
