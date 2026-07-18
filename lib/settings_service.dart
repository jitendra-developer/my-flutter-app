import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {

  final supabase = Supabase.instance.client;

  Future<Map<String, String>> getSettings() async {

    final response = await supabase
        .from('app_settings')
        .select();

    Map<String, String> settings = {};

    for (var row in response) {
      settings[row['setting_key']] = row['setting_value'];
    }

    return settings;
  }

}