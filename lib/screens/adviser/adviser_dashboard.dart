import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdviserDashboard extends StatelessWidget {
  const AdviserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('Adviser Dashboard')),
      body: Center(
        child: Text(
          'Adviser dashboard (coming next)',
          style: TextStyle(color: AppColors.mediumGrey),
        ),
      ),
    );
  }
}
