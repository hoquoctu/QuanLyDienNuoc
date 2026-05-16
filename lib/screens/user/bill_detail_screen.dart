import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/payment_model.dart';
import '../../services/bill_service.dart';
import '../../services/CloudinaryUpload.dart';
import '../../theme/app_theme.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;
  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final bool _submitting = false;
  PaymentModel? _payment;
  bool _loadingPayment = false;

  BillModel get bill => widget.bill;

  @override
  void initState() {
    super.initState();
    // Luôn tải thông tin thanh toán (nếu có)
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() => _loadingPayment = true);
    final payment = await BillService.instance.getPaymentByBill(bill.id);
    if (mounted) {
      setState(() {
        _payment = payment;
        _loadingPayment = false;
      });
    }
  }

  // ── Hiển thị bottom sheet chọn phương thức thanh toán ────────────────────
  void _showPaymentSheet() {
    String selectedMethod = 'cash';
    File? transferFile;
    String? transferPreviewPath;
    bool uploading = false;
    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickTransferImage() async {
            final picker = ImagePicker();
            final xfile = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1024,
              maxHeight: 1024,
              imageQuality: 85,
            );
            if (xfile != null) {
              setSheetState(() {
                transferFile = File(xfile.path);
                transferPreviewPath = xfile.path;
              });
            }
          }

          Future<void> submit() async {
            // Validate: nếu chuyển khoản phải có ảnh
            if (selectedMethod == 'transfer' && transferFile == null) {
              setSheetState(() =>
                  sheetError = 'Vui lòng chụp/chọn ảnh minh chứng chuyển khoản.');
              return;
            }

            setSheetState(() {
              uploading = true;
              sheetError = null;
            });

            String transferImageUrl = '';

            // Upload ảnh chuyển khoản lên Cloudinary nếu có
            if (selectedMethod == 'transfer' && transferFile != null) {
              final url = await uploadToCloudinary(transferFile!);
              if (url == null) {
                setSheetState(() {
                  uploading = false;
                  sheetError = 'Upload ảnh thất bại. Vui lòng thử lại.';
                });
                return;
              }
              transferImageUrl = url;
            }

            // Gửi thanh toán
            final err = await BillService.instance.submitPayment(
              billId: bill.id,
              ownerId: bill.ownerId,
              tenantId: bill.tenantId,
              method: selectedMethod,
              transferImage: transferImageUrl,
            );

            if (!ctx.mounted) return;

            if (err != null) {
              setSheetState(() {
                uploading = false;
                sheetError = err;
              });
            } else {
              Navigator.pop(ctx); // Đóng bottom sheet
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi thanh toán! Chờ chủ trọ xác nhận.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                Navigator.pop(context); // Quay lại danh sách
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tiêu đề ────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payment,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Thanh toán hóa đơn',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Chọn phương thức ────────────────────────────────────
                  const Text('Phương thức thanh toán',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MethodTile(
                          icon: Icons.money,
                          label: 'Tiền mặt',
                          selected: selectedMethod == 'cash',
                          onTap: () =>
                              setSheetState(() => selectedMethod = 'cash'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MethodTile(
                          icon: Icons.account_balance,
                          label: 'Chuyển khoản',
                          selected: selectedMethod == 'transfer',
                          onTap: () =>
                              setSheetState(() => selectedMethod = 'transfer'),
                        ),
                      ),
                    ],
                  ),

                  // ── Ảnh chuyển khoản (nếu chọn transfer) ───────────────
                  if (selectedMethod == 'transfer') ...[
                    const SizedBox(height: 16),
                    const Text('Ảnh minh chứng chuyển khoản',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: uploading ? null : pickTransferImage,
                      child: Container(
                        width: double.infinity,
                        height: transferPreviewPath != null ? 220 : 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: transferPreviewPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(transferPreviewPath!),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setSheetState(() {
                                          transferFile = null;
                                          transferPreviewPath = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: AppTheme.primary.withOpacity(0.5),
                                      size: 32),
                                  const SizedBox(height: 6),
                                  Text('Chọn ảnh chuyển khoản',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              AppTheme.primary.withOpacity(0.7),
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],

                  // ── Lỗi ─────────────────────────────────────────────────
                  if (sheetError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.errorColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(sheetError!,
                                style: const TextStyle(
                                    color: AppTheme.errorColor, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Nút xác nhận ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: uploading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: uploading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Xác nhận thanh toán',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widget hiển thị thông tin thanh toán ─────────────────────────────────
  Widget _buildPaymentInfoSection() {
    if (_loadingPayment) {
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

    if (_payment == null) {
      return const SizedBox.shrink();
    }

    final payment = _payment!;
    final isPending = bill.status == BillStatus.pending;
    final methodLabel = payment.method == 'cash' ? 'Tiền mặt' : 'Chuyển khoản';
    final methodIcon =
        payment.method == 'cash' ? Icons.money : Icons.account_balance;
    final bannerColor = isPending ? const Color(0xFFF59E0B) : AppTheme.successColor;
    final bannerBg = isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);
    final bannerTextColor = isPending ? const Color(0xFF92400E) : const Color(0xFF166534);
    final bannerText = isPending
        ? 'Đang chờ chủ trọ xác nhận'
        : 'Thanh toán đã được xác nhận';
    final bannerIcon = isPending
        ? Icons.hourglass_top_rounded
        : Icons.check_circle_rounded;

    return _InfoCard(
      title: 'Thông tin thanh toán',
      titleIcon: Icons.receipt_long,
      titleColor: AppTheme.primary,
      children: [
        // Banner trạng thái
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

        // Phương thức
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
                  DateFormat('dd/MM/yyyy · HH:mm').format(payment.createdAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),

        // Ảnh chuyển khoản (nếu có)
        if (payment.method == 'transfer' &&
            payment.transferImage.isNotEmpty) ...[
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
            onTap: () => _showFullImage(context, payment.transferImage),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                payment.transferImage,
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

  // ── Xem ảnh full screen ─────────────────────────────────────────────────
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
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    // Trạng thái hiển thị
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (bill.status) {
      case BillStatus.paid:
        statusColor = AppTheme.successColor;
        statusLabel = 'Đã thanh toán';
        statusIcon = Icons.check_circle_outline;
        break;
      case BillStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Chờ xác nhận';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case BillStatus.overdue:
        statusColor = Colors.deepOrange;
        statusLabel = 'Quá hạn';
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = AppTheme.errorColor;
        statusLabel = 'Chờ thanh toán';
        statusIcon = Icons.pending_outlined;
    }

    // Chỉ hiển thị nút thanh toán khi chưa TT (unpaid / overdue)
    final showPayButton =
        bill.status == BillStatus.unpaid || bill.status == BillStatus.overdue;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header gradient ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(bill.monthLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '${fmt.format(bill.total)}đ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('Chi tiết hóa đơn',
                style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Trạng thái ──────────────────────────────────────────
                _InfoCard(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(statusIcon,
                              color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trạng thái',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            Text(statusLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: statusColor)),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(bill.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Điện ────────────────────────────────────────────────
                _InfoCard(
                  title: 'Điện',
                  titleIcon: Icons.bolt,
                  titleColor: AppTheme.elecColor,
                  children: [
                    _Row(
                        label: 'Chỉ số cũ',
                        value:
                            '${bill.electric.oldNumber.toStringAsFixed(0)} kWh'),
                    _Row(
                        label: 'Chỉ số mới',
                        value:
                            '${bill.electric.newNumber.toStringAsFixed(0)} kWh'),
                    _Row(
                        label: 'Tiêu thụ',
                        value:
                            '${bill.electric.used.toStringAsFixed(0)} kWh',
                        bold: true),
                    _Row(
                        label: 'Đơn giá',
                        value:
                            '${fmt.format(bill.electric.unitPrice)}đ/kWh'),
                    _Row(
                        label: 'Thành tiền',
                        value: '${fmt.format(bill.electric.total)}đ',
                        bold: true,
                        color: AppTheme.elecColor),
                    // Ảnh công tơ điện
                    if (bill.electric.image != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          bill.electric.image!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: AppTheme.textHint)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Nước ────────────────────────────────────────────────
                _InfoCard(
                  title: 'Nước',
                  titleIcon: Icons.water_drop,
                  titleColor: AppTheme.waterColor,
                  children: [
                    _Row(
                        label: 'Chỉ số cũ',
                        value:
                            '${bill.water.oldNumber.toStringAsFixed(0)} m³'),
                    _Row(
                        label: 'Chỉ số mới',
                        value:
                            '${bill.water.newNumber.toStringAsFixed(0)} m³'),
                    _Row(
                        label: 'Tiêu thụ',
                        value: '${bill.water.used.toStringAsFixed(0)} m³',
                        bold: true),
                    _Row(
                        label: 'Đơn giá',
                        value:
                            '${fmt.format(bill.water.unitPrice)}đ/m³'),
                    _Row(
                        label: 'Thành tiền',
                        value: '${fmt.format(bill.water.total)}đ',
                        bold: true,
                        color: AppTheme.waterColor),
                    // Ảnh đồng hồ nước
                    if (bill.water.image != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          bill.water.image!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: AppTheme.textHint)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Tổng cộng ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '${fmt.format(bill.total)}đ',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Nút thanh toán ──────────────────────────────────────
                if (showPayButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _showPaymentSheet,
                      icon: const Icon(Icons.payment, size: 20),
                      label: const Text('Thanh toán ngay',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                // ── Thông tin thanh toán ──────────────────────────────────
                if (_loadingPayment || _payment != null) ...[
                  const SizedBox(height: 4),
                  _buildPaymentInfoSection(),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Method Tile ──────────────────────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textHint,
                size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Color? titleColor;
  final List<Widget> children;

  const _InfoCard({
    this.title,
    this.titleIcon,
    this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null)
                  Icon(titleIcon, color: titleColor, size: 18),
                if (titleIcon != null) const SizedBox(width: 6),
                Text(title!,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: titleColor ?? AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 0),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

// ── Row item ─────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _Row(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
