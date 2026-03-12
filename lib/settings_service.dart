import 'package:myapp/services/api_service.dart';

class SettingsService {
  Future<Map<String, String>> getSettings() async {
    final apiService = ApiService();
    return await apiService.getAppSettings(prefix: 'onboarding_');
  }
}