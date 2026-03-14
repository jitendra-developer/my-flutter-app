import 'package:myapp/services/api_service.dart';

class SettingsService {
  Future<Map<String, String>> getOnboardingSettings() async {
    final apiService = ApiService();
    // Fetch all onboarding keys using the prefix
    return await apiService.getAppSettings(prefix: 'onboarding_');
  }
}