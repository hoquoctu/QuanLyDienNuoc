import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/owner/bill_provider.dart';
import 'package:quanlydiennc_app/screens/owner/notification/notification_screen.dart';

import '../../providers/auth_provider.dart';

import '../../theme/app_theme.dart';

import 'room_block/room_block_list_screen.dart';
import 'invoice/create_invoice_screen.dart';
import 'invoice/invoice_list_screen.dart';
import 'settings_manager_screen.dart';

class HomeManagerScreen extends StatefulWidget {
  const HomeManagerScreen({super.key});

  @override
  State<HomeManagerScreen> createState() => _HomeManagerScreenState();
}

class _HomeManagerScreenState extends State<HomeManagerScreen> {
  int _tab = 0;

  final _pages = const [
    RoomBlockListScreen(),
    CreateInvoiceScreen(),
    NotificationScreen(),
    InvoiceListScreen(),
    SettingsManagerScreen(),
  ];

  final _labels = [
    'Dãy trọ',
    'Tạo HĐ',
    "thông báo",
    'Hóa đơn',
    'Cài đặt',
  ];

  final _icons = [
    Icons.apartment_outlined,
    Icons.add_circle_outline,
    Icons.notifications_none_outlined,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];

  final _activeIcons = [
    Icons.apartment,
    Icons.add_circle,
    Icons.notifications,
    Icons.receipt_long,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final ownerId = context.read<AuthProvider>().currentUser!.uid;

    final billPvd = context.watch<BillProvider>();

    // đếm bill chờ chủ trọ duyệtR
    final pendingCount = billPvd.allBills.where((bill) {
      return bill.idOwner.id == ownerId && bill.status.id == 'pending';
    }).length;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: _pages,
      ),

      // ───────────────── BOTTOM BAR ─────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_labels.length, (i) {
                final active = _tab == i;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _tab = i;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              active ? _activeIcons[i] : _icons[i],
                              size: 26,
                              color:
                                  active ? AppTheme.primary : AppTheme.textHint,
                            ),

                            // badge hóa đơn chờ duyệt
                            if (i == 2 && pendingCount > 0)
                              Positioned(
                                right: -8,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color:
                                active ? AppTheme.primary : AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
