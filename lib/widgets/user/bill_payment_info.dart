import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/payment_model.dart';
import '../../theme/app_theme.dart';
import 'info_card.dart';

class BillPaymentInfo extends StatelessWidget {
  final bool loading;
  final PaymentModel? payment;
  final BillModel bill;

  const BillPaymentInfo({
    super.key,
    required this.loading,
    required this.payment,
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (payment == null) {
      return const SizedBox.shrink();
    }

    final isPending = bill.status == BillStatus.pending;
    final methodLabel =
        payment!.method == 'cash' ? 'Tiền mặt' : 'Chuyển khoản';
    final methodIcon =
        payment!.method == 'cash' ? Icons.money : Icons.account_balance;
    final bannerColor =
        isPending ? const Color(0xFFF59E0B) : AppTheme.successColor;
    final bannerBg =
        isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);
    final bannerTextColor =
        isPending ? const Color(0xFF92400E) : const Color(0xFF166534);
    final bannerText = isPending
        ? 'Đang chờ chủ trọ xác nhận'
        : 'Thanh toán đã được xác nhận';
    final bannerIcon = isPending
        ? Icons.hourglass_top_rounded
        : Icons.check_circle_rounded;

    return InfoCard(
      title: 'Thông tin thanh toán',
      titleIcon: Icons.receipt_long,
      titleColor: AppTheme.primary,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bannerColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bannerText,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: bannerTextColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(methodIcon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phương thức',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(methodLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Ngày thanh toán',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(
                  DateFormat('dd/MM/yyyy · HH:mm').format(payment!.createdAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        if (payment!.method == 'transfer' &&
            payment!.transferImage.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 0),
          const SizedBox(height: 14),
          const Text('Ảnh minh chứng chuyển khoản',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullImage(context, payment!.transferImage),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                payment!.transferImage,
                fit: BoxFit.cover,
                height: 220,
                width: double.infinity,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 220,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade100,
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          color: AppTheme.textHint, size: 32)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('Nhấn để xem ảnh đầy đủ',
                style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
          ),
        ],
      ],
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                        child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
