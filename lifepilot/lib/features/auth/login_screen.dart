import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_panel.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _pin = '';
  bool _errorState = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometrics();
    });
  }

  Future<void> _triggerBiometrics() async {
    await ref.read(authProvider.notifier).authenticateBiometrically();
  }

  void _onKeyPress(String key) {
    if (_errorState) {
      setState(() {
        _errorState = false;
        _pin = '';
      });
    }
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
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorState = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref.read(authProvider.notifier).verifyPin(_pin);
    if (!success) {
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

  @override
  Widget build(BuildContext context) {
    final champagneGold = const Color(0xFFD6BD92);

    return Scaffold(
      body: Stack(
        children: [
          // Ambient wallpaper/glow base
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

          // Heavily blurred backdrop filter (35.0 sigma)
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 40,
                              color: champagneGold.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'SECURE VAULT LOCKED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: champagneGold,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                final filled = index < _pin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _errorState
                                        ? Colors.redAccent.withValues(
                                            alpha: filled ? 0.9 : 0.2,
                                          )
                                        : (filled
                                              ? champagneGold
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                )),
                                    border: Border.all(
                                      color: _errorState
                                          ? Colors.redAccent
                                          : (filled
                                                ? champagneGold
                                                : Colors.white.withValues(
                                                    alpha: 0.25,
                                                  )),
                                      width: 1.2,
                                    ),
                                    boxShadow: filled && !_errorState
                                        ? [
                                            BoxShadow(
                                              color: champagneGold.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 40),

                            // 4x3 Numeric Glass Pad Grid
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PinKey(
                                      child: const Text('1'),
                                      onTap: () => _onKeyPress('1'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('2'),
                                      onTap: () => _onKeyPress('2'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('3'),
                                      onTap: () => _onKeyPress('3'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PinKey(
                                      child: const Text('4'),
                                      onTap: () => _onKeyPress('4'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('5'),
                                      onTap: () => _onKeyPress('5'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('6'),
                                      onTap: () => _onKeyPress('6'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PinKey(
                                      child: const Text('7'),
                                      onTap: () => _onKeyPress('7'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('8'),
                                      onTap: () => _onKeyPress('8'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('9'),
                                      onTap: () => _onKeyPress('9'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PinKey(
                                      onTap: _triggerBiometrics,
                                      child: const Icon(
                                        Icons.fingerprint_rounded,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      child: const Text('0'),
                                      onTap: () => _onKeyPress('0'),
                                    ),
                                    const SizedBox(width: 24),
                                    _PinKey(
                                      onTap: _onBackspace,
                                      child: const Icon(
                                        Icons.backspace_outlined,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isPressed
                  ? champagneGold.withValues(alpha: 0.3)
                  : (_isHovered
                        ? champagneGold.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.06)),
              border: Border.all(
                color: _isPressed || _isHovered
                    ? champagneGold.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: champagneGold.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: IconTheme.merge(
              data: IconThemeData(
                color: _isHovered || _isPressed ? champagneGold : Colors.white,
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
    );
  }
}
