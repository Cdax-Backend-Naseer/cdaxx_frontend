import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/social_login_button.dart';
import '../../../providers/user_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final userProvider = context.read<UserProvider>();

    final success = await userProvider.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      mobile: _mobile.text.trim(),
      password: _password.text,
      confirmPassword: _confirm.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Registration failed'),
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
            if (context.canPop()) {
              context.pop();
            }
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

                  /// LOGO
                  Image.asset(
                    'assets/images/login.png',
                    height: 180,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Start your premium learning journey',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// GLASS CARD
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

                              /// DIVIDER
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'or',
                                      style: TextStyle(color: Colors.white54),
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

                              /// FORM
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    AppTextField(
                                      controller: _firstName,
                                      hint: 'First Name',
                                      icon: Icons.person_outline,
                                      isStyled: true,
                                    ),
                                    const SizedBox(height: 16),

                                    AppTextField(
                                      controller: _lastName,
                                      hint: 'Last Name',
                                      icon: Icons.person_outline,
                                      isStyled: true,
                                    ),
                                    const SizedBox(height: 16),

                                    AppTextField(
                                      controller: _email,
                                      hint: 'Email',
                                      icon: Icons.email_outlined,
                                      keyboardType:
                                      TextInputType.emailAddress,
                                      isStyled: true,
                                    ),
                                    const SizedBox(height: 16),

                                    AppTextField(
                                      controller: _mobile,
                                      hint: 'Mobile Number',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
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
                                    const SizedBox(height: 16),

                                    AppTextField(
                                      controller: _confirm,
                                      hint: 'Confirm Password',
                                      icon: Icons.lock_outline,
                                      obscureText: true,
                                      isStyled: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// CTA
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF38BDF8),
                                    foregroundColor: Colors.black,
                                    elevation: 12,
                                    shadowColor:
                                    const Color(0xFF38BDF8)
                                        .withOpacity(0.6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const CircularProgressIndicator()
                                      : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              /// LOGIN LINK
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      color: Colors.white70),
                                  children: [
                                    const TextSpan(
                                        text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Login',
                                      style: const TextStyle(
                                        color: Color(0xFF22D3EE),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap =
                                            () => context.push('/login'),
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
