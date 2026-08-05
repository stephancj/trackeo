import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../repositories/payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
    (ref) => RemotePaymentsRepository(ref.watch(dioProvider)));
final purchasablePlansProvider = FutureProvider<List<Map<String, dynamic>>>(
    (ref) => ref.watch(paymentsRepositoryProvider).getPlans());
