import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Database
import 'models/history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/login_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(HistoryModelAdapter().typeId)) {
    Hive.registerAdapter(HistoryModelAdapter());
  }

  // Handle schema migration: clear box if old data format incompatible
  try {
    await Hive.openBox<HistoryModel>('historyBox');
  } catch (e) {
    print('Schema mismatch detected, clearing history box: $e');
    await Hive.deleteBoxFromDisk('historyBox');
    await Hive.openBox<HistoryModel>('historyBox');
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FruiTell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE93E9D)),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
