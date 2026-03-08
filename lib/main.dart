import 'package:flutter/material.dart';
// import 'package:logbook_app_01/features/logbook/counter_view.dart';
import 'package:logbook_app_01/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
import 'package:logbook_app_01/features/logbook/models/log_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await MongoService().connect();

  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('logbook_box');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook App',
      debugShowCheckedModeBanner: false,
      home: const OnboardingView(),
    );
  }
}
