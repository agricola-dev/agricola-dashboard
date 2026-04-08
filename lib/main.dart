import 'dart:ui';

import 'package:agricola_dashboard/app.dart';
import 'package:agricola_dashboard/core/widgets/error_screen.dart';
import 'package:agricola_dashboard/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Widget build errors → branded error screen instead of grey/red Flutter screen.
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      ErrorScreen(details: details);

  // Flutter framework errors → log to console (wire to Crashlytics when added).
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Uncaught async / zone errors → log and let Flutter decide handling.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return false;
  };

  await Firebase.initializeApp(options: firebaseWebOptions);
  runApp(const ProviderScope(child: AgricolaDashboard()));
}
