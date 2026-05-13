import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HodDashboard extends StatelessWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('HOD Dashboard')),
      body: Center(
        child: Text(
          'HOD dashboard (coming next)',
          style: TextStyle(color: AppColors.mediumGrey),
        ),
      ),
    );
  }
}
