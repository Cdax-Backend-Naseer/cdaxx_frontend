import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/social_login_button.dart';
import '../../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.login(
      _email.text.trim(),
      _password.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020617),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Image.asset(
                    'assets/images/login.png',
                    height: 200,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Upgrade Your Skills',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Premium courses. Real results.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 36),

                  /// 🔥 PREMIUM GLASS CARD
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.35),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            children: [
                              /// SOCIAL LOGIN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SocialLoginButton(
                                    onPressed: () {},
                                    icon: Image.asset(
                                      'assets/images/Google.png',
                                      height: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  SocialLoginButton(
                                    onPressed: () {},
                                    icon: Image.asset(
                                      'assets/images/Apple.png',
                                      height: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  SocialLoginButton(
                                    onPressed: () {},
                                    icon: Image.asset(
                                      'assets/images/facebook.png',
                                      height: 28,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                    EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'or',
                                      style:
                                      TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    AppTextField(
                                      controller: _email,
                                      hint: 'Email',
                                      icon: Icons.email_outlined,
                                      isStyled: true,
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _password,
                                      hint: 'Password',
                                      icon: Icons.lock_outline,
                                      obscureText: true,
                                      isStyled: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed:
                                  _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF38BDF8),
                                    foregroundColor: Colors.black,
                                    elevation: 12,
                                    shadowColor:
                                    const Color(0xFF38BDF8)
                                        .withOpacity(0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const CircularProgressIndicator()
                                      : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      color: Colors.white70),
                                  children: [
                                    const TextSpan(
                                        text:
                                        "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign up',
                                      style: const TextStyle(
                                        color: Color(0xFF22D3EE),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer:
                                      TapGestureRecognizer()
                                        ..onTap = () =>
                                            context.push('/signup'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
