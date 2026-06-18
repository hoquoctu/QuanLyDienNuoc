import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _err;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _err = null);
    final auth = context.read<AuthProvider>();
    final err = await auth.forgotPassword(_emailCtrl.text.trim());
    if (err != null && mounted) {
      setState(() => _err = err);
    } else if (mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: AppTheme.surface,
      ),
      backgroundColor: AppTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: _sent ? _buildSuccess() : _buildForm(auth),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: AppTheme.successColor, size: 56),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email đã được gửi!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Hướng dẫn đặt lại mật khẩu đã được gửi về\n${_emailCtrl.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Nhập email đã đăng ký, hệ thống sẽ gửi link đặt lại mật khẩu về email đó.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        CustomTextField(
          label: 'Email',
          hint: 'Nhập email đã đăng ký',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          errorText: _err,
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppTheme.textHint, size: 20),
          onChanged: (_) => setState(() => _err = null),
        ),
        const SizedBox(height: 28),
        auth.loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _submit,
                child: const Text('Gửi yêu cầu'),
              ),
      ],
    );
  }
}
