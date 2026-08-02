import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static String cleanPhoneNumber(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) {
      return '91$digitsOnly';
    }
    return digitsOnly;
  }

  static String buildBillTextMessage({
    required String orderNumber,
    required double grandTotal,
    required String customerName,
    String loyaltyCardNumber = '',
    int visitCount = 1,
    String rewardStatus = '',
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🍽️ *Honeymoon Biryani - HMB Bills*');
    buffer.writeln('Dear ${customerName.isNotEmpty ? customerName : "Guest"}, thank you for dining with us!\n');
    buffer.writeln('📄 *Invoice #*: $orderNumber');
    buffer.writeln('💰 *Total Amount*: ₹${grandTotal.toStringAsFixed(2)}');

    if (loyaltyCardNumber.isNotEmpty) {
      buffer.writeln('💳 *Loyalty Card #*: $loyaltyCardNumber');
    }
    buffer.writeln('⭐ *Visit Count*: #$visitCount');

    if (rewardStatus.isNotEmpty) {
      buffer.writeln('🎉 *Reward Eligible*: $rewardStatus!');
    }

    buffer.writeln('\nWe look forward to serving you again soon! 🌟');
    return buffer.toString();
  }

  static Future<bool> sendBillViaWhatsApp({
    required String phone,
    required String orderNumber,
    required double grandTotal,
    required String customerName,
    String loyaltyCardNumber = '',
    int visitCount = 1,
    String rewardStatus = '',
  }) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final textMessage = buildBillTextMessage(
      orderNumber: orderNumber,
      grandTotal: grandTotal,
      customerName: customerName,
      loyaltyCardNumber: loyaltyCardNumber,
      visitCount: visitCount,
      rewardStatus: rewardStatus,
    );

    // Android Direct WhatsApp Deep Linking:
    // 1. For text messages: 'whatsapp://send?phone=91...' launches directly into the target chat.
    // 2. For PDF file attachments: Android OS ContentProvider / Intent ACTION_SEND standard
    //    requires user recipient confirmation inside WhatsApp for file attachment security.
    final encodedText = Uri.encodeComponent(textMessage);
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Fallback to web deep links
    final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedText');
    try {
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    final waMeUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
    try {
      if (await canLaunchUrl(waMeUri)) {
        return await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Fallback to Share Plus
    await Share.share(textMessage, subject: 'Invoice #$orderNumber - Honeymoon Biryani');
    return true;
  }
}
