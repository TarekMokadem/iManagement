import 'package:flutter/material.dart';

class CheckoutCancelScreen extends StatelessWidget {
  const CheckoutCancelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement annulé')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Le paiement a été annulé.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            )
          ],
        ),
      ),
    );
  }
}


