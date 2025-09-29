import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  // Get Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Login successful - navigate to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
      }
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = _getErrorMessage(error.message);
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error de conexión. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Credenciales incorrectas';
    } else if (message.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión';
    } else {
      return 'Error al iniciar sesión: $message';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      backgroundColor: Settings().colors.primary,
      child: SafeArea(
        child: Column(
          children: [
            Header(username: "Blaner", adminUsername: "Villegas"),
            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: CupertinoColors.black.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Iniciar Sesión',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navLargeTitleTextStyle
                            .copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.label
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      CupertinoTextField(
                        controller: _emailController,
                        placeholder: 'Correo electrónico',
                        prefix: const Icon(CupertinoIcons.mail, size: 18),
                        padding: const EdgeInsets.all(12),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CupertinoTextField(
                        controller: _passwordController,
                        placeholder: 'Contraseña',
                        prefix: const Icon(CupertinoIcons.lock, size: 18),
                        padding: const EdgeInsets.all(12),
                        obscureText: true,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 20),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.systemRed,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          color: Settings().colors.primaryContrast,
                          child: _isLoading
                              ? const CupertinoActivityIndicator()
                              : const Text('Entrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}