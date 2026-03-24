import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_session.dart';
import '../providers/exam_provider.dart';
import '../utils/time_formatter.dart';
import 'add_exam_sheet.dart';

class ExamCard extends StatelessWidget {
  final ExamSession session;

  const ExamCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: _cardColor(cs),
        borderRadius: BorderRadius.circular(22),
        border: session.status == ExamStatus.running
            ? Border.all(color: _accentColor(cs).withOpacity(0.25), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(session: session),
            const SizedBox(height: 12),
            _PhaseChips(session: session),
            const Spacer(),
            _TimeDisplay(session: session),
            const SizedBox(height: 10),
            _ProgressBar(session: session),
            const SizedBox(height: 12),
            _ActionRow(session: session),
          ],
        ),
      ),
    );
  }

  Color _cardColor(ColorScheme cs) {
    switch (session.status) {
      case ExamStatus.running:
        return switch (session.phase) {
          ExamPhase.toolFree =>
            Color.lerp(cs.surfaceContainerLow, cs.secondaryContainer, 0.2)!,
          ExamPhase.main =>
            Color.lerp(cs.surfaceContainerLow, cs.primaryContainer, 0.18)!,
          ExamPhase.nta =>
            Color.lerp(cs.surfaceContainerLow, cs.errorContainer, 0.15)!,
        };
      case ExamStatus.finished:
        return Color.lerp(cs.surfaceContainerLow, cs.tertiaryContainer, 0.25)!;
      case ExamStatus.paused:
        return Color.lerp(cs.surfaceContainerLow, cs.secondaryContainer, 0.12)!;
      case ExamStatus.idle:
        return cs.surfaceContainerLow;
    }
  }

  Color _accentColor(ColorScheme cs) {
    if (session.status != ExamStatus.running) return cs.primary;
    return switch (session.phase) {
      ExamPhase.toolFree => cs.secondary,
      ExamPhase.main => cs.primary,
      ExamPhase.nta => cs.error,
    };
  }
}

class _Header extends StatelessWidget {
  final ExamSession session;

  const _Header({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.read<ExamProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.subject,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontSize: 19,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (session.courseName.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  session.courseName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded,
              color: cs.onSurface.withOpacity(0.4), size: 20),
          tooltip: 'Optionen',
          onSelected: (v) => _onMenuSelected(context, v, provider),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined),
                SizedBox(width: 12),
                Text('Bearbeiten'),
              ]),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Row(children: [
                Icon(Icons.restart_alt_rounded),
                SizedBox(width: 12),
                Text('Zurücksetzen'),
              ]),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Text('Löschen',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  void _onMenuSelected(
      BuildContext context, String value, ExamProvider provider) {
    switch (value) {
      case 'edit':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: AddExamSheet(existingSession: session),
          ),
        );
      case 'reset':
        provider.resetSession(session.id);
      case 'delete':
        _confirmDelete(context, provider);
    }
  }

  void _confirmDelete(BuildContext context, ExamProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kurs entfernen?'),
        content: Text('„${session.subject}" wird aus der Liste entfernt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.removeSession(session.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}

class _PhaseChips extends StatelessWidget {
  final ExamSession session;

  const _PhaseChips({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    if (session.status != ExamStatus.idle) {
      chips.add(_StatusChip(session: session));
    }

    if (session.hasToolFree && session.status != ExamStatus.idle) {
      chips.add(_PhaseStepChip(
        label: 'Hilfsmittelfrei',
        icon: Icons.lock_outline_rounded,
        active: session.phase == ExamPhase.toolFree &&
            session.status == ExamStatus.running,
        done: session.phase != ExamPhase.toolFree,
        cs: cs,
      ));
      chips.add(_PhaseArrow(cs: cs));
    }

    chips.add(_PhaseStepChip(
      label: 'Klausur',
      icon: Icons.edit_outlined,
      active: session.phase == ExamPhase.main &&
          session.status == ExamStatus.running,
      done: session.phase == ExamPhase.nta ||
          session.status == ExamStatus.finished,
      cs: cs,
    ));

    if (session.hasNta) {
      chips.add(_PhaseArrow(cs: cs));
      chips.add(_PhaseStepChip(
        label: '+${session.ntaMinutes}min NTA',
        icon: Icons.more_time_rounded,
        active: session.phase == ExamPhase.nta &&
            session.status == ExamStatus.running,
        done: session.status == ExamStatus.finished,
        cs: cs,
        isNta: true,
      ));
    }

    return Wrap(spacing: 4, runSpacing: 4, children: chips);
  }
}

class _PhaseArrow extends StatelessWidget {
  final ColorScheme cs;

  const _PhaseArrow({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.arrow_forward_ios_rounded,
          size: 10, color: cs.onSurface.withOpacity(0.3)),
    );
  }
}

class _PhaseStepChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool done;
  final ColorScheme cs;
  final bool isNta;

  const _PhaseStepChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.done,
    required this.cs,
    this.isNta = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (active) {
      bg = isNta ? cs.errorContainer : cs.primaryContainer;
      fg = isNta ? cs.onErrorContainer : cs.onPrimaryContainer;
    } else if (done) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface.withOpacity(0.35);
    } else {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface.withOpacity(0.55);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(done ? Icons.check_rounded : icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ExamSession session;

  const _StatusChip({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (label, color, bg) = switch (session.status) {
      ExamStatus.idle => (
          'Bereit',
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest
        ),
      ExamStatus.running => (
          'Läuft',
          cs.onPrimaryContainer,
          cs.primaryContainer
        ),
      ExamStatus.paused => (
          'Pausiert',
          cs.onSecondaryContainer,
          cs.secondaryContainer
        ),
      ExamStatus.finished => (
          'Fertig',
          cs.onTertiaryContainer,
          cs.tertiaryContainer
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.status == ExamStatus.running)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 5),
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final ExamSession session;

  const _TimeDisplay({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isFinished = session.status == ExamStatus.finished;
    final isNtaPhase =
        session.phase == ExamPhase.nta && session.status == ExamStatus.running;
    final isToolFreePhase = session.phase == ExamPhase.toolFree &&
        session.status == ExamStatus.running;

    final timeColor = isFinished
        ? cs.tertiary
        : isNtaPhase
            ? cs.error
            : isToolFreePhase
                ? cs.secondary
                : cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            isFinished ? '00:00' : formatDuration(session.remaining),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w200,
              letterSpacing: -3,
              fontSize: 56,
              color: timeColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isToolFreePhase) ...[
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_bottom_rounded,
                      size: 13, color: cs.onSurface.withOpacity(0.45)),
                  const SizedBox(width: 5),
                  Text(
                    'Gesamt noch ${formatDuration(session.totalRemaining)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Center(child: _TimeSubLabel(session: session)),
      ],
    );
  }
}

class _TimeSubLabel extends StatelessWidget {
  final ExamSession session;

  const _TimeSubLabel({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurface.withOpacity(0.4),
          letterSpacing: 0.3,
        );

    if (session.status == ExamStatus.idle) {
      final parts = <String>[];
      if (session.hasToolFree) {
        parts.add(
            '${formatDurationLabel(session.toolFreeDuration!)} hilfsmittelfrei');
      }
      parts.add(formatDurationLabel(session.baseDuration));
      if (session.hasNta) parts.add('+${session.ntaMinutes}min NTA');
      return Text(parts.join(' · '), style: textStyle);
    }

    if (session.status == ExamStatus.finished) {
      return Text('Zeit abgelaufen', style: textStyle);
    }

    if (session.status == ExamStatus.paused) {
      return Text('Pausiert – ${formatDuration(session.remaining)} verbleibend',
          style: textStyle);
    }

    switch (session.phase) {
      case ExamPhase.toolFree:
        return Text('hilfsmittelfreier Teil · verbleibend', style: textStyle);

      case ExamPhase.main:
        if (session.hasNta) {
          return RichText(
            text: TextSpan(
              style: textStyle,
              children: [
                const TextSpan(text: 'verbleibend'),
                TextSpan(
                  text: '  ·  +${session.ntaMinutes}min NTA',
                  style: TextStyle(
                    color: cs.error.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: textStyle?.fontSize,
                    letterSpacing: textStyle?.letterSpacing,
                    fontFeatures: textStyle?.fontFeatures,
                  ),
                ),
              ],
            ),
          );
        }
        return Text('verbleibend', style: textStyle);

      case ExamPhase.nta:
        return Text(
          'NTA-Zusatzzeit · ${session.ntaMinutes}min',
          style: textStyle?.copyWith(color: cs.error.withOpacity(0.65)),
        );
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final ExamSession session;

  const _ProgressBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFinished = session.status == ExamStatus.finished;
    final isNta = session.phase == ExamPhase.nta;
    final isToolFree = session.phase == ExamPhase.toolFree;

    final barColor = isFinished
        ? cs.tertiary
        : isNta
            ? cs.error
            : isToolFree
                ? cs.secondary
                : cs.primary;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: isFinished ? 1.0 : session.phaseProgress,
            minHeight: 5,
            color: barColor,
            backgroundColor: barColor.withOpacity(0.12),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _phaseLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.32),
                  ),
            ),
            Text(
              formatDurationLabel(session.currentPhaseDuration),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.32),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String get _phaseLabel {
    if (session.status == ExamStatus.idle) return 'Nicht gestartet';
    if (session.status == ExamStatus.finished) return 'Abgeschlossen';
    return switch (session.phase) {
      ExamPhase.toolFree => 'Hilfsmittelfreier Teil',
      ExamPhase.main => 'Hauptteil',
      ExamPhase.nta => 'NTA-Zusatzzeit',
    };
  }
}

class _ActionRow extends StatelessWidget {
  final ExamSession session;

  const _ActionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExamProvider>();
    final cs = Theme.of(context).colorScheme;

    switch (session.status) {
      case ExamStatus.idle:
        return _wide(FilledButton.icon(
          onPressed: () => provider.startSession(session.id),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(session.hasToolFree
              ? 'Hilfsmittelfreien Teil starten'
              : 'Starten'),
        ));

      case ExamStatus.running:
        return _wide(FilledButton.icon(
          onPressed: () => provider.pauseSession(session.id),
          icon: const Icon(Icons.pause_rounded, size: 18),
          label: const Text('Pausieren'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
          ),
        ));

      case ExamStatus.paused:
        return Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => provider.startSession(session.id),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Fortsetzen'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => provider.resetSession(session.id),
            child: const Icon(Icons.restart_alt_rounded),
          ),
        ]);

      case ExamStatus.finished:
        return _wide(FilledButton.icon(
          onPressed: () => provider.resetSession(session.id),
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Neustarten'),
          style: FilledButton.styleFrom(
            backgroundColor: cs.tertiaryContainer,
            foregroundColor: cs.onTertiaryContainer,
          ),
        ));
    }
  }

  Widget _wide(Widget child) => SizedBox(width: double.infinity, child: child);
}
