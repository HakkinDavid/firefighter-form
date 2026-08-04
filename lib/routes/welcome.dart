import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/local_account.dart';
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
  bool _showOnlineAuthForm = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    Settings.instance.loadLocalAccounts();
  }

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
        _errorMessage = 'Por favor, completa todos los campos.';
      });
      return;
    }

    if (_isRegistering) {
      if (_confirmPasswordController.text.isEmpty ||
          _givenController.text.isEmpty ||
          _surname1Controller.text.isEmpty ||
          _surname2Controller.text.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor, completa todos los campos.';
        });
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Las contraseñas no coinciden.';
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
        final response =
            await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          await Settings.instance.switchActiveUser(response.user!.id);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
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

          await Settings.instance.switchActiveUser(response.user!.id);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
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

  Future<void> _handleLocalUserSelect(LocalUserAccount account) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Settings.instance.switchActiveUser(account.userId);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cambiar de usuario: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _promptRemoveAccount(LocalUserAccount account) async {
    final passwordPromptController = TextEditingController();
    String? errorText;

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('Eliminar cuenta'),
              content: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '¿Estás seguro de que deseas quitar a ${account.fullName} de este dispositivo?\n\nRequiere conexión y re-autenticación por contraseña.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: passwordPromptController,
                    placeholder: 'Contraseña para confirmar',
                    obscureText: true,
                    padding: const EdgeInsets.all(8),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () async {
                    if (passwordPromptController.text.isEmpty) {
                      setDialogState(() {
                        errorText = 'Ingresa tu contraseña para confirmar.';
                      });
                      return;
                    }
                    final success =
                        await Settings.instance.removeLocalAccountWithAuth(
                      account.userId,
                      passwordPromptController.text,
                    );
                    if (success) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (mounted) {
                        setState(() {});
                      }
                    } else {
                      setDialogState(() {
                        errorText =
                            'Fallo de autenticación. Verifica tu contraseña y conexión.';
                      });
                    }
                  },
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        );
      },
    );
    passwordPromptController.dispose();
  }

  String _getErrorMessage(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Credenciales incorrectas.';
    } else if (message.contains('Email not confirmed')) {
      return 'Confirma tu correo electrónico antes de iniciar sesión.';
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
              versionString: ServiceReliabilityEngineer.appVersion,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 320,
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
                    child: StreamBuilder<List<LocalUserAccount>>(
                      stream: Settings.instance.localAccountsStream,
                      initialData: Settings.instance.localAccounts,
                      builder: (context, snapshot) {
                        final localAccounts = snapshot.data ?? [];
                        final hasLocalAccounts = localAccounts.isNotEmpty;

                        // 1. Local Account Selector View
                        if (hasLocalAccounts && !_showOnlineAuthForm && !_isRecovering) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Usuarios locales',
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .navLargeTitleTextStyle
                                    .copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.label,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Toca tu usuario para acceder sin contraseña',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 240),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: localAccounts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final acc = localAccounts[index];
                                    final isActive =
                                        acc.userId == Settings.instance.userId;

                                    return GestureDetector(
                                      onTap: _isLoading
                                          ? null
                                          : () => _handleLocalUserSelect(acc),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Settings.instance.colors.primaryContrast
                                                  .withValues(alpha: 0.2)
                                              : CupertinoColors.extraLightBackgroundGray,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isActive
                                                ? Settings.instance.colors.primary
                                                : CupertinoColors.separator,
                                            width: isActive ? 1.5 : 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons.person_crop_circle_fill,
                                              size: 32,
                                              color: Settings.instance.colors.primary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    acc.fullName,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          CupertinoColors.label,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                  Text(
                                                    acc.roleName,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: CupertinoColors
                                                          .secondaryLabel,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              onPressed: () =>
                                                  _promptRemoveAccount(acc),
                                              child: const Icon(
                                                CupertinoIcons.trash,
                                                size: 18,
                                                color: CupertinoColors
                                                    .systemRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: CupertinoButton(
                                  color: Settings.instance.colors.primaryContrast,
                                  onPressed: () {
                                    setState(() {
                                      _showOnlineAuthForm = true;
                                      _isRegistering = false;
                                      _isRecovering = false;
                                      _errorMessage = '';
                                    });
                                  },
                                  child: const Text('Agregar usuario'),
                                ),
                              ),
                            ],
                          );
                        }

                        // 2. Password Recovery View
                        if (_isRecovering) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recuperar contraseña',
                                style: CupertinoTheme.of(context)
                                    .textTheme
                                    .navLargeTitleTextStyle
                                    .copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.label,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CupertinoTextField(
                                controller: _recoveryEmailController,
                                placeholder: 'Correo electrónico',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    CupertinoIcons.mail,
                                    size: 18,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                              ),
                              if (_isRecoveringStep2) ...[
                                const SizedBox(height: 14),
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
                                  padding: const EdgeInsets.all(12),
                                ),
                                const SizedBox(height: 14),
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
                                  padding: const EdgeInsets.all(12),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (_recoveryMessage.isNotEmpty)
                                Text(
                                  _recoveryMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _recoveryMessage.contains('enviado')
                                        ? CupertinoColors.activeGreen
                                        : CupertinoColors.systemRed,
                                  ),
                                ),
                              if (_recoveryMessage.isNotEmpty)
                                const SizedBox(height: 14),
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
                                                        type: OtpType.recovery,
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
                                                    _isRecoveringStep2 = false;
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
                                  const SizedBox(width: 10),
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
                                                _recoveryEmailController.clear();
                                                _otpController.clear();
                                                _newPasswordController.clear();
                                              });
                                            },
                                      child: const Text('Cancelar'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        // 3. Online Login & Registration View
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isRegistering
                                  ? 'Registrarse'
                                  : 'Iniciar sesión',
                              style: CupertinoTheme.of(context)
                                  .textTheme
                                  .navLargeTitleTextStyle
                                  .copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.label,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            CupertinoTextField(
                              controller: _emailController,
                              placeholder: 'Correo electrónico',
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Icon(
                                  CupertinoIcons.mail,
                                  size: 18,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                            ),
                            const SizedBox(height: 14),

                            // Password Field
                            CupertinoTextField(
                              controller: _passwordController,
                              placeholder: 'Contraseña',
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Icon(
                                  CupertinoIcons.lock,
                                  size: 18,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              obscureText: true,
                              autocorrect: false,
                            ),
                            const SizedBox(height: 14),

                            if (_isRegistering) ...[
                              CupertinoTextField(
                                controller: _confirmPasswordController,
                                placeholder: 'Confirmar contraseña',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    CupertinoIcons.lock,
                                    size: 18,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                obscureText: true,
                                autocorrect: false,
                              ),
                              const SizedBox(height: 14),
                              CupertinoTextField(
                                controller: _givenController,
                                placeholder: 'Nombre',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    CupertinoIcons.person,
                                    size: 18,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                autocorrect: false,
                              ),
                              const SizedBox(height: 14),
                              CupertinoTextField(
                                controller: _surname1Controller,
                                placeholder: 'Apellido paterno',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    CupertinoIcons.person,
                                    size: 18,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                autocorrect: false,
                              ),
                              const SizedBox(height: 14),
                              CupertinoTextField(
                                controller: _surname2Controller,
                                placeholder: 'Apellido materno',
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    CupertinoIcons.person,
                                    size: 18,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                autocorrect: false,
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 16),

                            // Error Message
                            if (_errorMessage.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed
                                      .withValues(alpha: 0.1),
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
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Action Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    color: Settings
                                        .instance
                                        .colors
                                        .primaryContrast,
                                    child: _isLoading
                                        ? const CupertinoActivityIndicator()
                                        : Text(_isRegistering ? 'Registrar' : 'Entrar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CupertinoButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              if (_isRegistering) {
                                                _isRegistering = false;
                                              } else if (hasLocalAccounts) {
                                                _showOnlineAuthForm = false;
                                              } else {
                                                _isRegistering = true;
                                              }
                                              _errorMessage = '';
                                            });
                                          },
                                    color: CupertinoColors.systemGrey,
                                    child: Text(
                                      _isRegistering
                                          ? 'Cancelar'
                                          : hasLocalAccounts
                                              ? 'Volver'
                                              : 'Registrarse',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (!_isRegistering) ...[
                              if (hasLocalAccounts)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isRegistering = true;
                                            _errorMessage = '';
                                          });
                                        },
                                  child: const Text(
                                    'Registrarse',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGrey,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
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
                        );
                      },
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
