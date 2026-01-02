/// Environment Configuration
/// Manages different environment settings (dev, staging, production)
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }
  
  static Map<String, dynamic> get config {
    switch (_currentEnvironment) {
      case Environment.development:
        return developmentConfig;
      case Environment.staging:
        return stagingConfig;
      case Environment.production:
        return productionConfig;
    }
  }
  
  static final Map<String, dynamic> developmentConfig = {
    // 'baseUrl': 'https://cdax-assessment-hosting-f284.onrender.com',
    'baseUrl': 'http://192.168.1.13:8080',
    'apiVersion': '/api',
    'enableLogging': true,
    'enableDebugMode': true,
    'databaseUrl': 'localhost:5432/cdax_dev',
  };


  
  static const Map<String, dynamic> stagingConfig = {
    'baseUrl': 'https://staging-api.cdax.com',
    'apiVersion': '/api/v1',
    'enableLogging': true,
    'enableDebugMode': false,
    'databaseUrl': 'staging-db.cdax.com:5432/cdax_staging',
  };
  
  static const Map<String, dynamic> productionConfig = {
    'baseUrl': 'https://api.cdax.com',
    'apiVersion': '/api/v1',
    'enableLogging': false,
    'enableDebugMode': false,
    'databaseUrl': 'prod-db.cdax.com:5432/cdax_prod',
  };
  
  // Getters for common config values
  static String get baseUrl => config['baseUrl'] as String;
  static String get apiVersion => config['apiVersion'] as String;
  static bool get enableLogging => config['enableLogging'] as bool;
  static bool get enableDebugMode => config['enableDebugMode'] as bool;
  static String get fullApiUrl => '$baseUrl$apiVersion';
}