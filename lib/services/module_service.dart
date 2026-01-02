import 'dart:convert';
import 'package:http/http.dart' as http;
import '/config/environment_config.dart';
import '../models/module_model.dart';

class ModuleService {
  static final baseUrl = 'http://192.168.1.6:8080';

  Future<List<ModuleModel>> fetchModules({
    required int courseId,
    required int userId,
  }) async {
    final url =
        '$baseUrl/modules/course/$courseId?userId=$userId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load modules');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => ModuleModel.fromJson(e)).toList();
  }
}
