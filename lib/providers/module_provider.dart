import 'package:flutter/material.dart';
import '../models/module_model.dart';
import '../services/module_service.dart';

class ModuleProvider extends ChangeNotifier {
  final ModuleService _service = ModuleService();

  bool _loading = false;
  String? _error;
  List<ModuleModel> _modules = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<ModuleModel> get modules => _modules;

  Future<void> loadModules({
    required int courseId,
    required int userId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _modules = await _service.fetchModules(
        courseId: courseId,
        userId: userId,
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _modules = [];
    _error = null;
  }
}
