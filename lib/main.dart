import 'package:flutter/material.dart';
import 'package:logbook_app_01/features/logbook/views/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_01/features/logbook/models/log_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Ambil daftar kamera yang tersedia di perangkat
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('logbook_box');
  await Hive.box<LogModel>('logbook_box').clear();

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
