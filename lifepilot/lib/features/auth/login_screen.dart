import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_panel.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Common states
  String _pin = '';
  bool _errorState = false;

  // Onboarding Wizard states
  int _onboardingStep = 1;
  final _usernameController = TextEditingController(text: 'Sankalpa');
  String _tempPin = '';

  // Recovery states
  final _recoveryKeyController = TextEditingController();
  bool _resettingPasscode = false;
  bool _hasAttemptedAutoBiometrics = false;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
      final authState = ref.read(authProvider);
      final isUnlocked = ref.read(authSessionProvider);
      if (!authState.isFirstTimeLaunch &&
          !authState.isRecovering &&
          !isUnlocked &&
          !_hasAttemptedAutoBiometrics) {
        _hasAttemptedAutoBiometrics = true;
        _triggerBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _recoveryKeyController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometrics() async {
    final isUnlocked = ref.read(authSessionProvider);
    if (isUnlocked) {
      return;
    }
    final success = await ref
        .read(authProvider.notifier)
        .authenticateBiometrically();
    if (success) {
      ref.read(authSessionProvider.notifier).markAsUnlocked();
    }
  }

  void _onKeyPress(String key) {
    if (_errorState) {
      setState(() {
        _errorState = false;
        _pin = '';
        _tempPin = '';
      });
    }

    final authState = ref.read(authProvider);

    // Onboarding PIN flow
    if (authState.isFirstTimeLaunch && _onboardingStep == 2) {
      if (_tempPin.length < 4) {
        setState(() {
          _tempPin += key;
        });
        if (_tempPin.length == 4) {
          _handleOnboardingAccountCreation();
        }
      }
      return;
    }

    // Reset passcode flow
    if (authState.isRecovering && _resettingPasscode) {
      if (_tempPin.length < 4) {
        setState(() {
          _tempPin += key;
        });
        if (_tempPin.length == 4) {
          _handleRecoveryPasscodeReset();
        }
      }
      return;
    }

    // Standard PIN login flow
    if (_pin.length < 4) {
      setState(() {
        _pin += key;
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    final authState = ref.read(authProvider);

    if (authState.isFirstTimeLaunch && _onboardingStep == 2) {
      if (_tempPin.isNotEmpty) {
        setState(() {
          _tempPin = _tempPin.substring(0, _tempPin.length - 1);
          _errorState = false;
        });
      }
      return;
    }

    if (authState.isRecovering && _resettingPasscode) {
      if (_tempPin.isNotEmpty) {
        setState(() {
          _tempPin = _tempPin.substring(0, _tempPin.length - 1);
          _errorState = false;
        });
      }
      return;
    }

    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorState = false;
      });
    }
  }

  Future<void> _handleOnboardingAccountCreation() async {
    final username = _usernameController.text.trim().isEmpty
        ? 'Sankalpa'
        : _usernameController.text.trim();
    await ref.read(authProvider.notifier).createAccount(username, _tempPin);
    setState(() {
      _onboardingStep = 3;
    });
  }

  Future<void> _handleRecoveryPasscodeReset() async {
    final success = await ref
        .read(authProvider.notifier)
        .resetPinWithRecoveryKey(_recoveryKeyController.text, _tempPin);
    if (success) {
      ref.read(authSessionProvider.notifier).markAsUnlocked();
      setState(() {
        _resettingPasscode = false;
        _tempPin = '';
        _pin = '';
      });
    } else {
      setState(() {
        _errorState = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _errorState) {
          setState(() {
            _tempPin = '';
            _errorState = false;
          });
        }
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref.read(authProvider.notifier).verifyPin(_pin);
    if (success) {
      ref.read(authSessionProvider.notifier).markAsUnlocked();
    } else {
      setState(() {
        _errorState = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _errorState) {
          setState(() {
            _pin = '';
            _errorState = false;
          });
        }
      });
    }
  }

  Future<void> _verifyRecoveryKey() async {
    final inputKey = _recoveryKeyController.text.trim().toUpperCase();
    if (inputKey.isEmpty) return;

    // Direct hash check to verify if the key is correct before prompting for PIN reset
    final authNotifier = ref.read(authProvider.notifier);
    final tempDummyPin = '9999';
    final isValid = await authNotifier.resetPinWithRecoveryKey(
      inputKey,
      tempDummyPin,
    );

    if (isValid) {
      // Re-lock so we can get user to set their actual new passcode
      authNotifier.lock();
      ref.read(authProvider.notifier).enterRecovery();
      setState(() {
        _resettingPasscode = true;
        _tempPin = '';
        _errorState = false;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1D1A1E),
          content: Text(
            'Invalid Recovery Key. Please try again.',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
  }

  void _copyRecoveryKey(String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1D1A1E),
        content: Text(
          'Recovery Key copied to clipboard',
          style: TextStyle(color: Color(0xFFD6BD92)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final champagneGold = const Color(0xFFD6BD92);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.backspace) {
            _onBackspace();
          } else if (key == LogicalKeyboardKey.digit0 ||
              key == LogicalKeyboardKey.numpad0) {
            _onKeyPress('0');
          } else if (key == LogicalKeyboardKey.digit1 ||
              key == LogicalKeyboardKey.numpad1) {
            _onKeyPress('1');
          } else if (key == LogicalKeyboardKey.digit2 ||
              key == LogicalKeyboardKey.numpad2) {
            _onKeyPress('2');
          } else if (key == LogicalKeyboardKey.digit3 ||
              key == LogicalKeyboardKey.numpad3) {
            _onKeyPress('3');
          } else if (key == LogicalKeyboardKey.digit4 ||
              key == LogicalKeyboardKey.numpad4) {
            _onKeyPress('4');
          } else if (key == LogicalKeyboardKey.digit5 ||
              key == LogicalKeyboardKey.numpad5) {
            _onKeyPress('5');
          } else if (key == LogicalKeyboardKey.digit6 ||
              key == LogicalKeyboardKey.numpad6) {
            _onKeyPress('6');
          } else if (key == LogicalKeyboardKey.digit7 ||
              key == LogicalKeyboardKey.numpad7) {
            _onKeyPress('7');
          } else if (key == LogicalKeyboardKey.digit8 ||
              key == LogicalKeyboardKey.numpad8) {
            _onKeyPress('8');
          } else if (key == LogicalKeyboardKey.digit9 ||
              key == LogicalKeyboardKey.numpad9) {
            _onKeyPress('9');
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Glows
            Positioned.fill(child: Container(color: const Color(0xFF0F0E11))),
            Positioned(
              top: -120,
              left: -120,
              width: 380,
              height: 380,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      champagneGold.withValues(alpha: 0.12),
                      champagneGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -150,
              width: 480,
              height: 480,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      champagneGold.withValues(alpha: 0.08),
                      champagneGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Frost blur layer (sigma 35.0)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: LifePilotGlassCard(
                          radius: 28,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          child: _buildActiveView(authState, champagneGold),
                        ),
                      ),
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

  Widget _buildActiveView(AuthState authState, Color gold) {
    if (authState.isFirstTimeLaunch) {
      return _buildOnboardingView(authState, gold);
    }
    if (authState.isRecovering) {
      return _buildRecoveryView(gold);
    }
    return _buildStandardLoginView(gold);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONBOARDING WIZARD VIEWS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOnboardingView(AuthState authState, Color gold) {
    switch (_onboardingStep) {
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars_rounded, size: 44, color: gold),
            const SizedBox(height: 16),
            const Text(
              'CREATE YOUR VAULT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Color(0xFFD6BD92),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Initialize offline local security',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: gold.withValues(alpha: 0.8)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: gold),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  if (_usernameController.text.trim().isNotEmpty) {
                    setState(() {
                      _onboardingStep = 2;
                    });
                  }
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 40, color: gold),
            const SizedBox(height: 16),
            const Text(
              'SET PASSCODE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Color(0xFFD6BD92),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a 4-digit security code',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            _buildDotsIndicator(_tempPin.length, gold),
            const SizedBox(height: 32),
            _buildKeypad(),
          ],
        );

      case 3:
        final recoveryKey = authState.recoveryKey ?? 'LP-XXXX-XXXX';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_rounded, size: 44, color: gold),
            const SizedBox(height: 16),
            const Text(
              'MASTER RECOVERY KEY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: Color(0xFFD6BD92),
              ),
            ),
            const SizedBox(height: 24),
            LifePilotGlassCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              cardGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gold.withValues(alpha: 0.12),
                  gold.withValues(alpha: 0.03),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    recoveryKey,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This is your air-gapped vault key. Copy it down. It cannot be recovered online.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _copyRecoveryKey(recoveryKey),
                    icon: Icon(Icons.copy_rounded, size: 16, color: gold),
                    label: Text(
                      'Copy to Clipboard',
                      style: TextStyle(
                        color: gold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  ref.read(authProvider.notifier).completeOnboarding();
                  ref.read(authSessionProvider.notifier).markAsUnlocked();
                },
                child: const Text('Complete Onboarding'),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASSCODE RECOVERY VIEWS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRecoveryView(Color gold) {
    if (_resettingPasscode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_reset_rounded, size: 44, color: gold),
          const SizedBox(height: 16),
          const Text(
            'RESET PASSCODE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: Color(0xFFD6BD92),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a new 4-digit security code',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          _buildDotsIndicator(_tempPin.length, gold),
          const SizedBox(height: 32),
          _buildKeypad(),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_open_rounded, size: 44, color: gold),
        const SizedBox(height: 16),
        const Text(
          'RECOVER ACCESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Color(0xFFD6BD92),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your 12-character Master Recovery Key',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _recoveryKeyController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            labelText: 'Recovery Key (LP-XXXX-XXXX)',
            labelStyle: TextStyle(color: gold.withValues(alpha: 0.8)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: gold),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).exitRecovery();
                  setState(() {
                    _recoveryKeyController.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _verifyRecoveryKey,
                child: const Text('Verify Key'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STANDARD LOGIN VIEW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStandardLoginView(Color gold) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 40,
          color: gold.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 16),
        Text(
          'SECURE VAULT LOCKED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: gold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome Back, Sankalpa',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 40),

        // Indicator Dots
        _buildDotsIndicator(_pin.length, gold),
        const SizedBox(height: 16),

        // Forgot Passcode Link
        TextButton(
          onPressed: () {
            ref.read(authProvider.notifier).enterRecovery();
          },
          child: Text(
            'Forgot Passcode?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: gold.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Numeric Keypad
        _buildKeypad(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDotsIndicator(int length, Color gold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _errorState
                ? Colors.redAccent.withValues(alpha: filled ? 0.9 : 0.2)
                : (filled ? gold : Colors.white.withValues(alpha: 0.12)),
            border: Border.all(
              color: _errorState
                  ? Colors.redAccent
                  : (filled ? gold : Colors.white.withValues(alpha: 0.25)),
              width: 1.2,
            ),
            boxShadow: filled && !_errorState
                ? [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PinKey(child: const Text('1'), onTap: () => _onKeyPress('1')),
            const SizedBox(width: 24),
            _PinKey(child: const Text('2'), onTap: () => _onKeyPress('2')),
            const SizedBox(width: 24),
            _PinKey(child: const Text('3'), onTap: () => _onKeyPress('3')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PinKey(child: const Text('4'), onTap: () => _onKeyPress('4')),
            const SizedBox(width: 24),
            _PinKey(child: const Text('5'), onTap: () => _onKeyPress('5')),
            const SizedBox(width: 24),
            _PinKey(child: const Text('6'), onTap: () => _onKeyPress('6')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PinKey(child: const Text('7'), onTap: () => _onKeyPress('7')),
            const SizedBox(width: 24),
            _PinKey(child: const Text('8'), onTap: () => _onKeyPress('8')),
            const SizedBox(width: 24),
            _PinKey(child: const Text('9'), onTap: () => _onKeyPress('9')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PinKey(
              onTap: _triggerBiometrics,
              child: const Icon(Icons.fingerprint_rounded, size: 28),
            ),
            const SizedBox(width: 24),
            _PinKey(child: const Text('0'), onTap: () => _onKeyPress('0')),
            const SizedBox(width: 24),
            _PinKey(
              onTap: _onBackspace,
              child: const Icon(Icons.backspace_outlined, size: 22),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKey extends StatefulWidget {
  const _PinKey({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final champagneGold = const Color(0xFFD6BD92);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : (_isHovered ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            width: 64,
            height: 64,
            child: LifePilotGlassCard(
              radius: 32,
              isPressed: _isPressed,
              padding: EdgeInsets.zero,
              cardGradient: _isPressed
                  ? LinearGradient(
                      colors: [
                        champagneGold.withValues(alpha: 0.15),
                        champagneGold.withValues(alpha: 0.05),
                      ],
                    )
                  : (_isHovered
                        ? LinearGradient(
                            colors: [
                              champagneGold.withValues(alpha: 0.08),
                              champagneGold.withValues(alpha: 0.02),
                            ],
                          )
                        : null),
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: _isHovered || _isPressed
                        ? champagneGold
                        : Colors.white,
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _isHovered || _isPressed
                          ? champagneGold
                          : Colors.white,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
