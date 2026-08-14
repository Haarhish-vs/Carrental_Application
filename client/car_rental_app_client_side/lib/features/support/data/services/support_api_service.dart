import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';

class SupportData {
  final String label;
  final String email;
  final String phone;
  final Map<String, DynamicPolicy> policiesMap;
  final List<DynamicPolicy> policiesList;

  SupportData({
    required this.label,
    required this.email,
    required this.phone,
    required this.policiesMap,
    required this.policiesList,
  });

  factory SupportData.fromJson(Map<String, dynamic> json) {
    final cust = json['customerSupport'] ?? {};
    final pMap = json['policiesMap'] as Map<String, dynamic>? ?? {};
    final pList = json['policiesList'] as List<dynamic>? ?? [];

    final Map<String, DynamicPolicy> parsedMap = {};
    pMap.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        parsedMap[key.toLowerCase()] = DynamicPolicy.fromJson(val);
      }
    });

    final List<DynamicPolicy> parsedList = pList
        .whereType<Map<String, dynamic>>()
        .map((e) => DynamicPolicy.fromJson(e))
        .toList();

    return SupportData(
      label: cust['label']?.toString() ?? '',
      email: cust['email']?.toString() ?? '',
      phone: cust['phone']?.toString() ?? '',
      policiesMap: parsedMap,
      policiesList: parsedList,
    );
  }

  factory SupportData.empty() {
    return SupportData(
      label: '',
      email: '',
      phone: '',
      policiesMap: {},
      policiesList: [],
    );
  }
}

class DynamicPolicy {
  final dynamic id;
  final String title;
  final String policyType;
  final String content;

  DynamicPolicy({
    required this.id,
    required this.title,
    required this.policyType,
    required this.content,
  });

  factory DynamicPolicy.fromJson(Map<String, dynamic> json) {
    return DynamicPolicy(
      id: json['id'],
      title: json['title']?.toString() ?? json['policy_type']?.toString() ?? '',
      policyType: json['policy_type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }
}

class SupportApiService {
  static Future<SupportData> fetchSupportDetails() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/support/details');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return SupportData.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      // Ignore network errors and return empty object (data will come from backend)
    }
    return SupportData.empty();
  }
}
