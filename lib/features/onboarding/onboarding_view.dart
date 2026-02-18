import 'package:flutter/material.dart';
import 'package:logbook_app_01/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/hello.gif",
      "title": "Selamat Datang",
      "desc": "Kelola hitunganmu dengan mudah dan cepat.",
    },
    {
      "image": "assets/copy.gif",
      "title": "Riwayat Otomatis",
      "desc": "Semua aktivitas counter tersimpan rapi.",
    },
    {
      "image": "assets/check.gif",
      "title": "Siap Digunakan",
      "desc": "Mulai produktivitasmu sekarang juga.",
    },
  ];

  void _nextStep() {
    if (step == _pages.length) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    } else {
      setState(() => step++);
    }
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == step - 1;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade700 : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[step - 1];

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(page["image"]!, height: 120),
              const SizedBox(height: 24),
              // Title
              Text(
                page["title"]!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                page["desc"]!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildIndicator(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text(step == _pages.length ? "Start" : "Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
