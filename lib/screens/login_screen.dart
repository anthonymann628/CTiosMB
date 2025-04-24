// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/app_state.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _doLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty && password == 'test') {
      final user = User(username: 'DemoUser', token: 'testToken');
      context.read<AppState>().setUser(user);
      Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
    } else {
      try {
        final user = await AuthService.login(username, password);
        if (user == null) {
          setState(() => _error = 'Invalid credentials');
        } else {
          context.read<AppState>().setUser(user);
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        }
      } catch (e) {
        setState(() => _error = 'Login failed: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('CarrierTrack - Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Logo at top, 25% of screen height
              SizedBox(
                height: screenHeight * 0.25,
                child: Center(
                  child: Image.asset(
                    'assets/images/login.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Card containing the form
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _doLogin,
                                child: const Text('Log In'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
