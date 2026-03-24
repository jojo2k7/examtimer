import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/exam_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExamProvider(),
      child: const KlausurtimerApp(),
    ),
  );
}
