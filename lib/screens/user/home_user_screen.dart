import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'bill_list_user_screen.dart';
import 'dashboard_user_screen.dart';
import 'room_user_screen.dart';
import 'settings_user_screen.dart';

class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({super.key});
  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  int _tab = 0;

  final _pages = const [
    DashboardUserScreen(),
    BillListUserScreen(),
    RoomUserScreen(),
    SettingsUserScreen(),
  ];

  final _labels = ['Tổng quan', 'Hóa đơn', 'Phòng trọ', 'Cài đặt'];
  final _icons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.home_outlined,
    Icons.settings_outlined,
  ];
  final _activeIcons = [
    Icons.dashboard,
    Icons.receipt_long,
    Icons.home,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
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
                    onTap: () => setState(() => _tab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? _activeIcons[i] : _icons[i],
                          color: active
                              ? AppTheme.primary
                              : AppTheme.textHint,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppTheme.primary
                                : AppTheme.textHint,
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
