import 'package:flutter/foundation.dart';
import '../models/module_model.dart';
import '../services/module_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

class ModuleProvider extends ChangeNotifier {
  final ModuleService _service = ModuleService();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _loading = false;
  String? _error;
  List<ModuleModel> _modules = [];

  // Offline mode flag
  bool _isOfflineMode = false;

  // Current context
  int? _currentCourseId;
  int? _currentUserId;

  bool get isLoading => _loading;
  String? get error => _error;
  List<ModuleModel> get modules => _modules;
  bool get isOfflineMode => _isOfflineMode;
  int? get currentCourseId => _currentCourseId;

  /// Load modules with offline support
  Future<void> loadModules({
    required int courseId,
    required int userId,
    bool forceRefresh = false,
  }) async {
    // Prevent duplicate loading of same course
    if (_loading && _currentCourseId == courseId) {
      debugPrint('⚠️ Already loading modules for course $courseId');
      return;
    }

    // If we already have modules for this course and not forcing refresh, return
    if (!forceRefresh && _currentCourseId == courseId && _modules.isNotEmpty) {
      debugPrint('📚 Using cached modules for course $courseId (${_modules.length} modules)');
      return;
    }

    _currentCourseId = courseId;
    _currentUserId = userId;
    _loading = true;
    _error = null;
    notifyListeners();

    final isOnline = _connectivityService.isConnected;

    debugPrint('📚 Loading modules for course $courseId (Online: $isOnline, Force: $forceRefresh)');

    try {
      // Try network if online and not forcing offline
      if (isOnline && !forceRefresh) {
        await _loadFromNetwork(courseId, userId);
      }
      // Try cache if offline or forceRefresh is false and network failed
      else if (!forceRefresh) {
        final loadedFromCache = await _loadFromCache(courseId);
        if (!loadedFromCache && isOnline) {
          // Cache empty but online, try network
          await _loadFromNetwork(courseId, userId);
        }
      }
      // Force refresh - only network (must be online)
      else if (forceRefresh && isOnline) {
        await _loadFromNetwork(courseId, userId, forceRefresh: true);
      }
      // Force refresh but offline - show error
      else if (forceRefresh && !isOnline) {
        _error = 'Cannot refresh: No internet connection';
        _isOfflineMode = true;
        debugPrint('❌ Cannot force refresh modules while offline');
      }

    } catch (e) {
      debugPrint('❌ Error loading modules: $e');
      _error = e.toString();

      // Try to load from cache as fallback
      final loadedFromCache = await _loadFromCache(courseId);
      if (!loadedFromCache) {
        _modules = [];
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load modules from network and cache them
  Future<void> _loadFromNetwork(int courseId, int userId, {bool forceRefresh = false}) async {
    debugPrint('🌐 Loading modules from network for course $courseId...');

    final modules = await _service.fetchModules(
      courseId: courseId,
      userId: userId,
    );

    _modules = modules;
    _isOfflineMode = false;
    _error = null;

    debugPrint('✅ Loaded ${modules.length} modules from network');

    // Cache the modules for offline use
    await _cacheModulesLocally(courseId, modules);
    await _cacheService.updateLastSync();
  }

  /// Load modules from cache (offline mode)
  Future<bool> _loadFromCache(int courseId) async {
    debugPrint('💾 Loading modules from cache for course $courseId...');

    final cachedModules = await _cacheService.getCachedModules(courseId.toString());

    if (cachedModules != null && cachedModules.isNotEmpty) {
      try {
        final List<ModuleModel> modules = [];
        for (var moduleJson in cachedModules) {
          try {
            final module = ModuleModel.fromJson(moduleJson);
            modules.add(module);
          } catch (e) {
            debugPrint('⚠️ Error parsing cached module: $e');
          }
        }

        if (modules.isNotEmpty) {
          _modules = modules;
          _isOfflineMode = true;
          _error = null;
          debugPrint('✅ Loaded ${modules.length} modules from cache (OFFLINE MODE)');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Error processing cached modules: $e');
      }
    }

    debugPrint('⚠️ No cached modules found for course $courseId');
    return false;
  }

  /// Cache modules locally
  Future<void> _cacheModulesLocally(int courseId, List<ModuleModel> modules) async {
    try {
      final modulesJson = modules.map((m) => m.toJson()).toList();
      await _cacheService.cacheModules(courseId.toString(), modulesJson);
      debugPrint('💾 ${modules.length} modules cached for course $courseId');
    } catch (e) {
      debugPrint('❌ Failed to cache modules: $e');
    }
  }

  /// Refresh modules (pull to refresh)
  Future<void> refreshModules(int courseId, int userId) async {
    if (!_connectivityService.isConnected) {
      _error = 'Cannot refresh: No internet connection';
      notifyListeners();
      return;
    }

    debugPrint('🔄 Force refreshing modules for course $courseId...');
    await loadModules(
      courseId: courseId,
      userId: userId,
      forceRefresh: true,
    );
  }

  /// Get a specific module by ID (with offline support)
  Future<ModuleModel?> getModuleById(int moduleId) async {
    // Check if we already have it in memory
    try {
      final cachedModule = _modules.firstWhere((m) => m.id == moduleId);
      return cachedModule;
    } catch (e) {
      // Not found in memory, continue to cache
    }

    // Try to load from cache if we have course context
    if (_currentCourseId != null) {
      final cachedModules = await _cacheService.getCachedModules(_currentCourseId!.toString());
      if (cachedModules != null) {
        for (var moduleJson in cachedModules) {
          try {
            final module = ModuleModel.fromJson(moduleJson);
            if (module.id == moduleId) {
              return module;
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing cached module: $e');
          }
        }
      }
    }

    return null;
  }

  /// Check if modules are cached for a course
  Future<bool> hasCachedModules(int courseId) async {
    return await _cacheService.hasCachedModules(courseId.toString());
  }

  /// Clear modules for a specific course
  void clearModulesForCourse(int courseId) {
    if (_currentCourseId == courseId) {
      _modules = [];
      _currentCourseId = null;
      _error = null;
      _isOfflineMode = false;
      notifyListeners();
      debugPrint('🗑️ Cleared modules for course $courseId');
    }
  }

  /// Clear all modules
  void clear() {
    _modules = [];
    _error = null;
    _currentCourseId = null;
    _currentUserId = null;
    _isOfflineMode = false;
    _loading = false;
    debugPrint('🗑️ All modules cleared');
    notifyListeners();
  }

  /// Get module count
  int get moduleCount => _modules.length;

  /// Get unlocked module count
  int get unlockedModuleCount => _modules.where((m) => !m.isLocked).length;

  /// Get locked module count
  int get lockedModuleCount => _modules.where((m) => m.isLocked).length;

  /// Get next locked module (first module that is locked)
  ModuleModel? get nextLockedModule {
    try {
      return _modules.firstWhere((m) => m.isLocked);
    } catch (e) {
      return null;
    }
  }

  /// Get current active module (first unlocked module)
  ModuleModel? get currentActiveModule {
    try {
      return _modules.firstWhere((m) => !m.isLocked);
    } catch (e) {
      return null;
    }
  }

  /// Debug method to print module state
  void debugState() {
    debugPrint('\n📚 ModuleProvider State:');
    debugPrint('   ├─ Course ID: $_currentCourseId');
    debugPrint('   ├─ Modules: ${_modules.length}');
    debugPrint('   ├─ Unlocked: $unlockedModuleCount');
    debugPrint('   ├─ Locked: $lockedModuleCount');
    debugPrint('   ├─ Offline Mode: $_isOfflineMode');
    debugPrint('   ├─ Loading: $_loading');
    debugPrint('   └─ Error: $_error');

    for (var module in _modules) {
      debugPrint('      📘 ${module.title} (ID: ${module.id})');
      debugPrint('         └─ Locked: ${module.isLocked}');
    }
  }
}