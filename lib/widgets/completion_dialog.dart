import 'package:flutter/material.dart';

import '../models/exam_session.dart';
import '../utils/time_formatter.dart';

class CompletionDialog extends StatelessWidget {
  final CompletionEvent event;

  const CompletionDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = event.session;
    final isToolFree = event.type == CompletionType.toolFree;
    final isNta = event.type == CompletionType.nta;

    final (Color iconBg, Color iconFg, IconData icon, String eyebrow) =
        switch (event.type) {
      CompletionType.toolFree => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
          Icons.lock_open_rounded,
          'Hilfsmittelfreier Teil beendet',
        ),
      CompletionType.main => (
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
          Icons.timer_off_rounded,
          'Zeit abgelaufen',
        ),
      CompletionType.nta => (
          cs.errorContainer,
          cs.onErrorContainer,
          Icons.timer_off_rounded,
          'NTA-Zeit abgelaufen',
        ),
    };

    final message = isToolFree
        ? session.toolFreeCompletionMessage
        : session.completionMessage;

    final continuesHint = isToolFree
        ? 'Der Hauptteil startet automatisch.'
        : (isNta
            ? null
            : session.hasNta
                ? 'NTA-Zeit läuft noch.'
                : null);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      title: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: iconFg),
          ),
          const SizedBox(height: 18),
          Text(
            eyebrow,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isToolFree ? cs.secondary : cs.tertiary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            session.subject,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (session.courseName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              session.courseName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            isToolFree
                ? '${formatDurationLabel(session.toolFreeDuration!)} · hilfsmittelfrei'
                : isNta
                    ? '${session.ntaMinutes}min NTA'
                    : formatDurationLabel(session.baseDuration),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(height: 1.6, color: cs.onSurface),
            ),
          ),
          if (continuesHint != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: cs.onSurface.withOpacity(0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    continuesHint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurface.withOpacity(0.4)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
