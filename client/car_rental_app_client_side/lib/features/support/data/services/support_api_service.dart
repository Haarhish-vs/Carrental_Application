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
      label: cust['label']?.toString() ?? 'Customer Support',
      email: cust['email']?.toString() ?? 'adminsupport@gmail.com',
      phone: cust['phone']?.toString() ?? '8825430047',
      policiesMap: parsedMap,
      policiesList: parsedList,
    );
  }

  factory SupportData.defaultFallback() {
    return SupportData(
      label: 'Customer Support',
      email: 'adminsupport@gmail.com',
      phone: '8825430047',
      policiesMap: {
        'privacy': DynamicPolicy(
          id: 1,
          title: 'Privacy Policy',
          policyType: 'privacy',
          content: 'We protect your personal and account information. We do not sell your personal data.',
        ),
        'security': DynamicPolicy(
          id: 2,
          title: 'Security Policy',
          policyType: 'security',
          content: 'User accounts and data are protected through secure encryption protocols.',
        ),
        'terms': DynamicPolicy(
          id: 3,
          title: 'Terms & Conditions',
          policyType: 'terms',
          content: 'By using our app, you agree to comply with our community guidelines.',
        ),
        'cancellation': DynamicPolicy(
          id: 4,
          title: 'Cancellation Policy',
          policyType: 'cancellation',
          content: 'Free cancellation up to 24 hours before your trip starts.',
        ),
        'refund': DynamicPolicy(
          id: 5,
          title: 'Refund Policy',
          policyType: 'refund',
          content: 'Refund eligibility depends on booking terms. Eligible refunds take 5-7 business days.',
        ),
      },
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
      title: json['title']?.toString() ?? json['policy_type']?.toString() ?? 'Policy',
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
      // Return clean fallback defaults on network/timeout error
    }
    return SupportData.defaultFallback();
  }
}
