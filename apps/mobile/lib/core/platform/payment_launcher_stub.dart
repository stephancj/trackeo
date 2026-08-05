import 'package:url_launcher/url_launcher.dart';

Future<bool> openPaymentUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
