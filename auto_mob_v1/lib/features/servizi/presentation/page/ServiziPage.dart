import 'package:flutter/material.dart';

class ServiziPage extends StatelessWidget {
  const ServiziPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1C23),
      body: Center(
        child: Text(
          'SERVIZI\nIn arrivo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7361AC),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
