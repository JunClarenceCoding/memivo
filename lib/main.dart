import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const MemivoApp());
}

class MemivoApp extends StatelessWidget {
  const MemivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memivo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6A3BAF),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}


  
