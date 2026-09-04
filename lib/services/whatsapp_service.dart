import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/store_settings.dart';

class WhatsAppService {
  static Future<bool> sendReceipt({
    required Sale sale,
    required StoreSettings settings,
    required String phoneNumber,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(sale.createdAt),
    );

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedPhone = cleanPhone;
    if (cleanPhone.startsWith('0')) {
      formattedPhone = '94' + cleanPhone.substring(1);
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🧾 *RECEIPT: ${settings.storeName}*');
    if (settings.address.isNotEmpty) buffer.writeln('📍 ${settings.address}');
    if (settings.phone.isNotEmpty) buffer.writeln('📞 ${settings.phone}');
    buffer.writeln('--------------------------------');
    buffer.writeln('📋 *Bill No:* ${sale.billNo}');
    buffer.writeln('📅 *Date:* $dateStr');
    buffer.writeln('🏷️ *Type:* ${sale.saleType.toUpperCase()}');
    if (sale.customerName != null) buffer.writeln('👤 *Customer:* ${sale.customerName}');
    buffer.writeln('--------------------------------');
    buffer.writeln('*ITEMS:*');

    for (var item in sale.items) {
      buffer.writeln('• ${item.name} x ${item.qty} = ${settings.currency} ${item.subtotal.toStringAsFixed(2)}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ${settings.currency} ${sale.subtotal.toStringAsFixed(2)}');
    if (sale.discount > 0) {
      buffer.writeln('Discount: - ${settings.currency} ${sale.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('💰 *NET TOTAL: ${settings.currency} ${sale.total.toStringAsFixed(2)}*');
    buffer.writeln('💳 *Payment:* ${sale.paymentMethod.toUpperCase()}');
    buffer.writeln('--------------------------------');
    buffer.writeln('${settings.receiptHeader}');
    buffer.writeln('${settings.receiptFooter}');
    buffer.writeln('🙏 *Thank you for your business!*');

    final message = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/$formattedPhone?text=$message');

    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
