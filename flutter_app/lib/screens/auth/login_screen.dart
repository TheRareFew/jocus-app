import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/routes.dart';
import '../../core/widgets/text/animated_gradient_text.dart';
import '../../core/widgets/buttons/animated_gradient_button.dart';
import '../../core/widgets/buttons/account_switch_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthProvider>().signInWithEmailAndPassword(
              _emailController.text,
              _passwordController.text,
            );
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.dashboard);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'image.jpg',
              fit: BoxFit.cover,
              alignment: Alignment(0.03,
                  0), // Shifted slightly to the left while maintaining vertical center
            ).animate().fadeIn(duration: 1200.ms),
          ),
          // Overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Content
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedGradientText(
                          text: 'JOCUS',
                          fontSize: 72,
                          letterSpacing: 4,
                        )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .fadeIn(duration: 600.ms)
                        .then()
                        .scale(
                          begin: const Offset(0.2, 0.2),
                          end: const Offset(1.1, 1.1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.1, 1.1),
                          end: const Offset(1, 1),
                          duration: 400.ms,
                        )
                        .then()
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withOpacity(0.8),
                          angle: 45,
                          size: 8,
                        )
                        .then()
                        .rotate(
                          begin: -0.02,
                          end: 0.02,
                          duration: 1000.ms,
                        )
                        .then()
                        .rotate(
                          begin: 0.02,
                          end: -0.02,
                          duration: 1000.ms,
                        )
                        .then()
                        .rotate(
                          begin: 0,
                          end: 6.28319, // 2π radians (360 degrees)
                          duration: 800.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .rotate(
                          begin: 0,
                          end: -6.28319,
                          duration: 800.ms,
                          curve: Curves.easeInOut,
                        ),
                        const SizedBox(height: 48),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ).animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideX(begin: -0.2, end: 0),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                          ),
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ).animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideX(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        AnimatedGradientButton(
                          onPressed: _isLoading ? null : _login,
                          text: 'Login',
                          isLoading: _isLoading,
                        )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .animate(
                            autoPlay: true,
                            onPlay: (controller) => controller.repeat(),
                          )
                          .shimmer(
                            delay: 600.ms,
                            duration: 1800.ms,
                          )
                          .animate(
                            autoPlay: true,
                            onPlay: (controller) => controller.repeat(),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.02, 1.02),
                            duration: 1000.ms,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.02, 1.02),
                            end: const Offset(1, 1),
                            duration: 1000.ms,
                          ),
                        const SizedBox(height: 16),
                        AccountSwitchButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, Routes.signup),
                          text: 'Don\'t have an account? Sign up',
                        ).animate()
                          .fadeIn(delay: 1000.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
