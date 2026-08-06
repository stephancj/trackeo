import 'package:dio/dio.dart';

abstract class PaymentsRepository {
  Future<List<Map<String, dynamic>>> getPlans();
  Future<Map<String, dynamic>> checkout(String planId, {String? provider, String? couponCode});
  Future<Map<String, dynamic>> status(String reference);
}

class RemotePaymentsRepository implements PaymentsRepository {
  final Dio dio;
  RemotePaymentsRepository(this.dio);
  @override
  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await dio.get<List<dynamic>>('/payments/plans');
    return response.data!
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> checkout(String planId,
      {String? provider, String? couponCode}) async {
    final response = await dio.post<Map<String, dynamic>>('/payments/checkout',
        data: {
          'planId': planId,
          if (provider != null) 'provider': provider,
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
        });
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> status(String reference) async {
    final response =
        await dio.get<Map<String, dynamic>>('/payments/$reference/status');
    return response.data!;
  }
}
