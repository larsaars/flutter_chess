import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<String> get rootDir async {
  final directory = await getApplicationDocumentsDirectory();
  // For your reference print the AppDoc directory
  return directory.path;
}

class ContextSingleton {
  static ContextSingleton _instance;
  final BuildContext _context;

  ContextSingleton(this._context) {
    _instance = this;
  }

  static get context {
    return _instance._context;
  }
}