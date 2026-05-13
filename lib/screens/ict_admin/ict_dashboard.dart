import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class IctDashboard extends StatelessWidget {
  const IctDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('ICT Dashboard')),
      body: Center(
        child: Text(
          'ICT dashboard (coming next)',
          style: TextStyle(color: AppColors.mediumGrey),
        ),
      ),
    );
  }
}
