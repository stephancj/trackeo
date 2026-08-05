class Entitlements {
  final String subscriptionId;
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? nextBillingDate;
  final String planId;
  final String planCode;
  final String planName;
  final bool accessAllowed;
  final Map<String, dynamic> features;

  const Entitlements({
    required this.subscriptionId,
    required this.status,
    required this.trialEndsAt,
    required this.nextBillingDate,
    required this.planId,
    required this.planCode,
    required this.planName,
    required this.accessAllowed,
    required this.features,
  });

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'] as Map<String, dynamic>;
    final plan = json['plan'] as Map<String, dynamic>;
    return Entitlements(
      subscriptionId: subscription['id'] as String,
      status: subscription['status'] as String,
      trialEndsAt: _date(subscription['trialEndsAt']),
      nextBillingDate: _date(subscription['nextBillingDate']),
      planId: plan['id'] as String,
      planCode: plan['code'] as String,
      planName: plan['name'] as String,
      accessAllowed: json['accessAllowed'] as bool? ?? false,
      features: Map<String, dynamic>.from(
        json['features'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  bool has(String code) => accessAllowed && features[code] == true;

  int limit(String code, {int fallback = 0}) {
    final value = features[code];
    return value is num ? value.toInt() : fallback;
  }

  static DateTime? _date(dynamic value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}
