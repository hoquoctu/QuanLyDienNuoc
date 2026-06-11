import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/bill_model.dart';
import '../../services/CloudinaryUpload.dart';
import '../../services/manager/bill_service.dart';
import '../../theme/app_theme.dart';
import 'method_tile.dart';

Future<void> showBillPaymentSheet(BuildContext context, BillModel bill) {
  String selectedMethod = 'cash';
  File? transferFile;
  String? transferPreviewPath;
  bool uploading = false;
  String? sheetError;

  return showModalBottomSheet(
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

          if (selectedMethod == 'transfer' && transferFile != null) {
            final url = await uploadToCloudinaryOnForlder(transferFile!,
                folder: 'Room_Zy/payments');
            if (url == null) {
              setSheetState(() {
                uploading = false;
                sheetError = 'Upload ảnh thất bại. Vui lòng thử lại.';
              });
              return;
            }
            transferImageUrl = url;
          }

          final err = await BillService().submitPayment(
            billId: bill.id,
            ownerId: bill.idOwner.id,
            tenantId: bill.idTenant.id,
            method: selectedMethod,
            transferImage: transferImageUrl,
            tenantName: bill.nameTenant,
            roomNumber: bill.roomNumberName,
          );

          if (!ctx.mounted) return;

          if (err != null) {
            setSheetState(() {
              uploading = false;
              sheetError = err;
            });
          } else {
            Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi thanh toán! Chờ chủ trọ xác nhận.'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
              Navigator.pop(context);
            }
          }
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                const Text('Phương thức thanh toán',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MethodTile(
                        icon: Icons.money,
                        label: 'Tiền mặt',
                        selected: selectedMethod == 'cash',
                        onTap: () =>
                            setSheetState(() => selectedMethod = 'cash'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MethodTile(
                        icon: Icons.account_balance,
                        label: 'Chuyển khoản',
                        selected: selectedMethod == 'transfer',
                        onTap: () =>
                            setSheetState(() => selectedMethod = 'transfer'),
                      ),
                    ),
                  ],
                ),
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
