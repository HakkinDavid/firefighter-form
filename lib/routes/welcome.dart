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
  final _confirmPasswordController = TextEditingController();
  final _givenController = TextEditingController();
  final _surname1Controller = TextEditingController();
  final _surname2Controller = TextEditingController();
  // Recovery state and controllers
  bool _isRecovering = false;
  bool _isRecoveringStep2 = false;
  final _recoveryEmailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  String _recoveryMessage = '';
  bool _isLoading = false;
  bool _isRegistering = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _givenController.dispose();
    _surname1Controller.dispose();
    _surname2Controller.dispose();
    _recoveryEmailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos';
      });
      return;
    }

    if (_isRegistering) {
      if (_confirmPasswordController.text.isEmpty ||
          _givenController.text.isEmpty ||
          _surname1Controller.text.isEmpty ||
          _surname2Controller.text.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, completa todos los campos';
        });
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Las contraseñas no coinciden';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!_isRegistering) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          await Settings.instance.setUser();
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/home");
          }
        }
      } else {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          await Supabase.instance.client.rpc(
            'register_user',
            params: {
              'p_given_name': _givenController.text.trim(),
              'p_surname1': _surname1Controller.text.trim(),
              'p_surname2': _surname2Controller.text.trim(),
            },
          );

          await Settings.instance.setUser();
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/home");
          }
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
      backgroundColor: Settings.instance.colors.primary,
      child: SafeArea(
        child: Column(
          children: [
            Header(
              username: Settings.instance.self?.fullName,
              adminUsername: Settings.instance.watcher?.fullName,
            ),
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
                  child: Supabase.instance.client.auth.currentUser != null
                      ? SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            onPressed: () async {
                              await Settings.instance.setUser();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  "/home",
                                );
                              }
                            },
                            color: Settings.instance.colors.primaryContrast,
                            child: _isLoading
                                ? const CupertinoActivityIndicator()
                                : const Text('Entrar'),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                _isRegistering
                                    ? 'Registrarse'
                                    : _isRecovering
                                    ? 'Recuperar contraseña'
                                    : 'Iniciar Sesión',
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .navLargeTitleTextStyle
                                    .copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.label,
                                    ),
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              CupertinoTextField(
                                controller: _emailController,
                                placeholder: 'Correo electrónico',
                                prefix: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: const Icon(
                                    CupertinoIcons.mail,
                                    size: 18,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                              ),

                              if (!_isRecovering) ...[
                                const SizedBox(height: 16),
                                // Password Field
                                CupertinoTextField(
                                  controller: _passwordController,
                                  placeholder: 'Contraseña',
                                  prefix: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: const Icon(
                                      CupertinoIcons.lock,
                                      size: 18,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  obscureText: true,
                                  autocorrect: false,
                                ),
                                const SizedBox(height: 16),

                                if (_isRegistering) ...[
                                  // Confirm Password Field
                                  CupertinoTextField(
                                    controller: _confirmPasswordController,
                                    placeholder: 'Confirmar contraseña',
                                    prefix: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: const Icon(
                                        CupertinoIcons.lock,
                                        size: 18,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    obscureText: true,
                                    autocorrect: false,
                                  ),
                                  const SizedBox(height: 16),

                                  // Given Name Field
                                  CupertinoTextField(
                                    controller: _givenController,
                                    placeholder: 'Nombre',
                                    prefix: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: const Icon(
                                        CupertinoIcons.person,
                                        size: 18,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    autocorrect: false,
                                  ),
                                  const SizedBox(height: 16),

                                  // Surname1 Field
                                  CupertinoTextField(
                                    controller: _surname1Controller,
                                    placeholder: 'Apellido paterno',
                                    prefix: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: const Icon(
                                        CupertinoIcons.person,
                                        size: 18,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    autocorrect: false,
                                  ),
                                  const SizedBox(height: 16),

                                  // Surname2 Field
                                  CupertinoTextField(
                                    controller: _surname2Controller,
                                    placeholder: 'Apellido materno',
                                    prefix: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: const Icon(
                                        CupertinoIcons.person,
                                        size: 18,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    autocorrect: false,
                                  ),
                                  const SizedBox(height: 20),
                                ] else
                                  const SizedBox(height: 20),
                              ],

                              // Error Message
                              if (_errorMessage.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemRed
                                        .withOpacity(0.1),
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

                              if (_errorMessage.isNotEmpty)
                                const SizedBox(height: 16),

                              // Buttons & Recovery Flow
                              if (_isRecovering) ...[
                                if (_isRecoveringStep2) ...[
                                  CupertinoTextField(
                                    controller: _otpController,
                                    placeholder: 'Código recibido por correo',
                                    keyboardType: TextInputType.number,
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(left: 12),
                                      child: Icon(
                                        CupertinoIcons.number,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CupertinoTextField(
                                    controller: _newPasswordController,
                                    placeholder: 'Nueva contraseña',
                                    obscureText: true,
                                    prefix: const Padding(
                                      padding: EdgeInsets.only(left: 12),
                                      child: Icon(
                                        CupertinoIcons.lock,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                if (_recoveryMessage.isNotEmpty)
                                  Text(
                                    _recoveryMessage,
                                    style: TextStyle(
                                      color:
                                          _recoveryMessage.contains('enviado')
                                          ? CupertinoColors.activeGreen
                                          : CupertinoColors.systemRed,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CupertinoButton(
                                        color: Settings
                                            .instance
                                            .colors
                                            .primaryContrast,
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                if (!_isRecoveringStep2) {
                                                  setState(() {
                                                    _recoveryMessage = '';
                                                  });
                                                  try {
                                                    await Supabase
                                                        .instance
                                                        .client
                                                        .auth
                                                        .resetPasswordForEmail(
                                                          _recoveryEmailController
                                                              .text
                                                              .trim(),
                                                        );
                                                    setState(() {
                                                      _isRecoveringStep2 = true;
                                                      _recoveryMessage =
                                                          'Enlace enviado. Revisa tu correo.';
                                                    });
                                                  } catch (e) {
                                                    setState(() {
                                                      _recoveryMessage =
                                                          'No se pudo enviar el enlace. Intenta nuevamente.';
                                                    });
                                                  }
                                                } else {
                                                  setState(() {
                                                    _recoveryMessage = '';
                                                  });
                                                  try {
                                                    await Supabase
                                                        .instance
                                                        .client
                                                        .auth
                                                        .verifyOTP(
                                                          token: _otpController
                                                              .text
                                                              .trim(),
                                                          type:
                                                              OtpType.recovery,
                                                          email:
                                                              _recoveryEmailController
                                                                  .text
                                                                  .trim(),
                                                        );
                                                    await Supabase
                                                        .instance
                                                        .client
                                                        .auth
                                                        .updateUser(
                                                          UserAttributes(
                                                            password:
                                                                _newPasswordController
                                                                    .text
                                                                    .trim(),
                                                          ),
                                                        );
                                                    setState(() {
                                                      _isRecovering = false;
                                                      _isRecoveringStep2 =
                                                          false;
                                                      _recoveryMessage = '';
                                                      _recoveryEmailController
                                                          .clear();
                                                      _otpController.clear();
                                                      _newPasswordController
                                                          .clear();
                                                    });
                                                  } catch (e) {
                                                    setState(() {
                                                      _recoveryMessage =
                                                          'Código inválido o expirado. Intenta nuevamente.';
                                                    });
                                                  }
                                                }
                                              },
                                        child: Text(
                                          !_isRecoveringStep2
                                              ? 'Enviar enlace'
                                              : 'Confirmar',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CupertinoButton(
                                        color: CupertinoColors.systemGrey,
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                setState(() {
                                                  _isRecovering = false;
                                                  _isRecoveringStep2 = false;
                                                  _recoveryMessage = '';
                                                  _recoveryEmailController
                                                      .clear();
                                                  _otpController.clear();
                                                  _newPasswordController
                                                      .clear();
                                                });
                                              },
                                        child: const Text('Cancelar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: CupertinoButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        color: Settings
                                            .instance
                                            .colors
                                            .primaryContrast,
                                        child: _isLoading
                                            ? const CupertinoActivityIndicator()
                                            : const Text('Entrar'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (!_isRegistering)
                                      Expanded(
                                        child: CupertinoButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _isRegistering = true;
                                                    _errorMessage = '';
                                                  });
                                                },
                                          color: CupertinoColors.systemGrey,
                                          child: const Text('Registrar'),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: CupertinoButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _isRegistering = false;
                                                    _errorMessage = '';
                                                  });
                                                },
                                          color: CupertinoColors.systemGrey,
                                          child: const Text('Cancelar'),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isRecovering = true;
                                            _isRecoveringStep2 = false;
                                            _recoveryMessage = '';
                                            _recoveryEmailController.clear();
                                            _otpController.clear();
                                            _newPasswordController.clear();
                                          });
                                        },
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
