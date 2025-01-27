import 'dart:async';
import 'package:flutter/material.dart';

// Used in Wait a Ride Feature to prevent abuse of use

class CooldownButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool verified;
  final String alert;

  const CooldownButton(
      {super.key,
      required this.child,
      required this.onPressed,
      required this.verified,
      required this.alert});

  @override
  _CooldownButtonState createState() => _CooldownButtonState();
}

class _CooldownButtonState extends State<CooldownButton> {
  bool _isCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _isCooldown = false;
          timer.cancel();
        }
      });
    });
  }

  void _handleTap() {
    if (!_isCooldown && widget.verified) {
      widget.onPressed();
      setState(() {
        _isCooldown = true;
        _cooldownSeconds = 60; // Reset cooldown time to 60 seconds
      });
      _startCooldownTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.alert),
          duration: const Duration(seconds: 2), // Adjust duration as needed
        ),
      );
    }
  }

  Widget get _buttonText {
    if (_isCooldown) {
      return Text('$_cooldownSeconds', style: TextStyle(fontSize: 10));
    } else {
      return widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: (_isCooldown || !widget.verified) ? Colors.grey : Colors.blue,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(child: _buttonText),
      ),
    );
  }
}
