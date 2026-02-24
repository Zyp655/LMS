import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/rive_login_character.dart';
import '../../../../core/widgets/rive_progress_indicator.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/utils/error_dialog_handler.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final GlobalKey<RiveLoginCharacterState> _riveKey = GlobalKey();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    emailController.addListener(_onEmailChanged);
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      _riveKey.currentState?.startChecking();
    } else {
      _riveKey.currentState?.stopChecking();
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      _riveKey.currentState?.handsUp();
    } else {
      _riveKey.currentState?.handsDown();
    }
  }

  void _onEmailChanged() {
    final text = emailController.text;
    final direction = (text.length * 2.0).clamp(0.0, 100.0);
    _riveKey.currentState?.setLookDirection(direction);
  }

  @override
  void dispose() {
    emailController.removeListener(_onEmailChanged);
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng Ký Tài Khoản")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RiveLoginCharacter(key: _riveKey, height: 200),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              focusNode: _emailFocusNode,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: passwordController,
              focusNode: _passwordFocusNode,
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                    if (!_obscurePassword) {
                      _riveKey.currentState?.handsDown();
                    } else if (_passwordFocusNode.hasFocus) {
                      _riveKey.currentState?.handsUp();
                    }
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 20),

            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  _riveKey.currentState?.fail();
                  ErrorDialogHandler.showError(context, state.failure);
                } else if (state is AuthSuccess) {
                  _riveKey.currentState?.success();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đăng ký thành công! Hãy đăng nhập."),
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (!mounted) return;
                    Navigator.pop(context);
                  });
                }
              },
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const RiveProgressIndicator(height: 50, width: 200);
                }
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        SignUpRequested(
                          email: emailController.text,
                          password: passwordController.text,
                        ),
                      );
                    },
                    child: const Text("Đăng Ký"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
