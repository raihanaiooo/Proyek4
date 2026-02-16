import 'package:flutter/material.dart';
import 'package:logbook_app_01/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;
  void _nextStep() {
    setState(() => step++);
    if (step > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ini Onboarding View')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Onboarding Step: $step",
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextStep,
              child: Text(step == 3 ? "Selesai" : "Lanjutkan"),
            ),
          ],
        ),
      ),
    );
  }
}
