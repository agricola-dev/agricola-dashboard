import 'package:agricola_dashboard/features/shell/presentation/header.dart';
import 'package:agricola_dashboard/features/shell/presentation/sidebar.dart';
import 'package:flutter/material.dart';

/// Top-level layout: sidebar + header + page content.
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const DashboardHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
