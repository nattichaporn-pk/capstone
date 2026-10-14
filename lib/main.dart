import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'focus_hub_screen.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    throw StateError(
      'ไม่พบ SUPABASE_URL / SUPABASE_ANON_KEY — รันด้วย '
      'flutter run --dart-define-from-file=env.json',
    );
  }

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFE5E5E5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                elevation: 8,
                child: child,
              ),
            ),
          ),
        );
      },
      home: const FocusHubScreen(),
    );
  }
}