import 'package:flutter/material.dart';
import 'package:genui_template/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qyzbtuwakojmzjpdtnai.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5emJ0dXdha29qbXpqcGR0bmFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MDAwOTEsImV4cCI6MjA5ODA3NjA5MX0.T1Ty21Sd9zKYSan9RJBnJbPOL9cCjm-ISkjqxJN8VT0',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: false,
    ),
  );
  runApp(const MainApp());
}
