import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/bh_room_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/boarding_house_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/room_provider.dart';
import 'providers/room_block_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/owner/home_manager_screen.dart';
import 'screens/user/home_user_screen.dart';
import 'theme/app_theme.dart';

class QuanLyDienNuocApp extends StatelessWidget {
  const QuanLyDienNuocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BoardingHouseProvider()),
        ChangeNotifierProvider(create: (_) => BhRoomProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => RoomBlockProvider()),
      ],
      child: MaterialApp(
        title: 'SmartUtility - Quản lý điện nước',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.init();

    // Init RoomProvider and RoomBlockProvider for all users
    await context.read<RoomProvider>().init();
    await context.read<RoomBlockProvider>().init();

    // Sau khi auth xong, khởi tạo provider phù hợp với role
    final user = auth.currentUser;
    if (user != null && user.isOwner) {
      context.read<BoardingHouseProvider>().initForOwner(user.uid);
    } else if (user != null && !user.isOwner) {
      // User thường: stream phòng và hóa đơn từ Firebase
      context.read<BhRoomProvider>().initForUser(user.uid);
      context.read<BillProvider>().initForUser(user.uid);
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'SmartUtility',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white70),
            ],
          ),
        ),
      );
    }

    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const LoginScreen();
    if (user.role == UserRole.owner) return const HomeManagerScreen();
    return const HomeUserScreen();
  }
}
