import 'dart:collection';

import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage(this.errors, {super.key});

  final HashSet<String> errors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // width: 400,
        // height: 200,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: Colors.white),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Text(
                  "There are errors in the config file, please fix them and try again:",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(color: Colors.redAccent),
                ),
                Text(
                  "\n${errors.join('\n')}",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
