import 'package:flutter/material.dart';
import 'package:memivo/routes/app_routes.dart';
import 'package:memivo/widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6FF),
      body:SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //App title and tagline
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration:  BoxDecoration(
                      color: const Color(0xFFFAF6FF),
                    ),
                    child: Image.asset(
                      'assets/images/memivo_logo.png',
                    )
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'Memivo',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3D2C5E),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              const Text(
                'Organize your life,\nremember what matters.',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF9B89B8),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 42,),

              //Feature Cards
              FeatureCard(
                title: 'Birthday Reminder',
                subtitle: 'Never forget a birthday',
                icon: Icons.cake_rounded,
                backgroundColor: const Color(0xFFFFF0F7),
                borderColor: const Color(0xFFF7D0E8),
                iconBackground: const Color(0xFFF9C6E0),
                iconColor: const Color(0xFFC4689A),
                titleColor: const Color(0xFF8B2D5E),
                subtitleColor: const Color(0xFFC4689A),
                onTap: () => Navigator.pushNamed(context, AppRoutes.birthday),
              ),

              FeatureCard(
                title: 'To-Do List',
                subtitle: 'Stay on top of your tasks',
                icon: Icons.checklist_rounded,
                backgroundColor: const Color(0xFFF0FAF2),
                borderColor: const Color(0xFFC8EDD0),
                iconBackground: const Color(0xFFC3E8CB),
                iconColor: const Color(0xFF5A9E67),
                titleColor: const Color(0xFF2A5E35),
                subtitleColor: const Color(0xFF5A9E67),
                onTap: () => Navigator.pushNamed(context, AppRoutes.todo),
              ),

              FeatureCard(
                title: 'Cafe Journal',
                subtitle: 'Log your cafe drinks',
                icon: Icons.local_cafe_rounded,
                backgroundColor: const Color(0xFFFFF8EE),
                borderColor: const Color(0xFFF5DFB0),
                iconBackground: const Color(0xFFF5DFB0),
                iconColor: const Color(0xFFB07A30),
                titleColor: const Color(0xFF6B4200),
                subtitleColor: const Color(0xFFB07A30),
                onTap: () => Navigator.pushNamed(context, AppRoutes.cafe),
              ),
            ],
          ),
        )
      )
    );
  }
}