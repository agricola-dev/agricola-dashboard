import 'package:agricola_dashboard/core/analytics/analytics_provider.dart';
import 'package:agricola_dashboard/features/shell/presentation/header.dart';
import 'package:agricola_dashboard/features/shell/presentation/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Top-level layout: sidebar + header + page content.
/// Tracks page views (via [GoRouterState] dependency) and scroll depth.
class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  String? _lastPath;
  String? _scrollPath;
  final _firedThresholds = <int>{};

  static const _scrollThresholds = [25, 50, 75, 100];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = GoRouterState.of(context).uri.path;
    if (path != _lastPath) {
      _lastPath = path;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(analyticsServiceProvider).logPageView(path);
        }
      });
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.maxScrollExtent <= 0) return false;
    final path = GoRouterState.of(context).uri.path;
    if (path != _scrollPath) {
      _scrollPath = path;
      _firedThresholds.clear();
    }
    final percent =
        (notification.metrics.pixels / notification.metrics.maxScrollExtent * 100)
            .round()
            .clamp(0, 100);
    for (final threshold in _scrollThresholds) {
      if (percent >= threshold && !_firedThresholds.contains(threshold)) {
        _firedThresholds.add(threshold);
        ref.read(analyticsServiceProvider).logScrollDepth(
              depthPercent: threshold,
              screen: path,
            );
      }
    }
    return false;
  }

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
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
