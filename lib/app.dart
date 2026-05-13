import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/room_provider.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'providers/boarding_house_provider.dart';
import 'providers/bill_provider.dart';
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
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => BoardingHouseProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
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

    // Sau khi auth xong, nếu là owner thì init dãy trọ luôn
    final user = auth.currentUser;
    if (user != null && user.isOwner) {
      context.read<BoardingHouseProvider>().initForOwner(user.uid);
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
