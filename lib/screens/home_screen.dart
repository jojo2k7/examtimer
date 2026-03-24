import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_session.dart';
import '../providers/exam_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/add_exam_sheet.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/exam_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<ExamProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (_isShowingDialog || !mounted) return;
    final next = context.read<ExamProvider>().nextCompletion;
    if (next != null) _showCompletionDialog(next);
  }

  void _showCompletionDialog(CompletionEvent event) {
    _isShowingDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionDialog(event: event),
    ).then((_) {
      _isShowingDialog = false;
      if (!mounted) return;
      context.read<ExamProvider>().dismissCompletion();
    });
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExamProvider>(),
        child: const AddExamSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Consumer<ExamProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return Scaffold(
            backgroundColor: cs.surface,
            body: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            titleSpacing: 16,
            title: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Klausurtimer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      germanDate(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
                if (provider.hasAnySessions) ...[
                  const SizedBox(width: 16),
                  _LiveIndicator(provider: provider),
                ],
              ],
            ),
            actions: [
              if (provider.canStartAll)
                FilledButton.icon(
                  onPressed: provider.startAll,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Alle starten'),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _openAddSheet,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Kurs hinzufügen',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: provider.hasAnySessions
              ? _BeamerGrid(provider: provider)
              : const _EmptyState(),
          floatingActionButton: provider.hasAnySessions
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openAddSheet,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Kurs hinzufügen'),
                ),
        );
      },
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  final ExamProvider provider;

  const _LiveIndicator({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running =
        provider.sessions.where((s) => s.status == ExamStatus.running).length;
    if (running == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$running läuft',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BeamerGrid extends StatefulWidget {
  final ExamProvider provider;

  const _BeamerGrid({required this.provider});

  @override
  State<_BeamerGrid> createState() => _BeamerGridState();
}

class _BeamerGridState extends State<_BeamerGrid>
    with SingleTickerProviderStateMixin {
  int _pageIndex = 0;
  Timer? _rotationTimer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const int _pageSize = 4;
  static const Duration _rotateDuration = Duration(seconds: 10);

  int get _pageCount => (widget.provider.sessions.length / _pageSize).ceil();

  bool get _needsRotation => widget.provider.sessions.length > _pageSize;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.value = 1.0;
    _startRotation();
  }

  @override
  void didUpdateWidget(_BeamerGrid old) {
    super.didUpdateWidget(old);
    final pageCount = _pageCount;
    if (_pageIndex >= pageCount) {
      setState(() => _pageIndex = 0);
    }
    if (_needsRotation && _rotationTimer == null) {
      _startRotation();
    } else if (!_needsRotation) {
      _stopRotation();
    }
  }

  void _startRotation() {
    if (!_needsRotation) return;
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(_rotateDuration, (_) => _advancePage());
  }

  void _stopRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  Future<void> _advancePage() async {
    if (!mounted) return;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _pageIndex = (_pageIndex + 1) % _pageCount;
    });
    await _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<ExamSession> get _currentPageSessions {
    final sessions = widget.provider.sessions;
    final start = _pageIndex * _pageSize;
    final end = (start + _pageSize).clamp(0, sessions.length);
    return sessions.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sessions = _currentPageSessions;
    final itemCount = sessions.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 12.0;
        const spacing = 12.0;
        const dotsHeight = 32.0;

        final rows = itemCount <= 2 ? 1 : 2;
        final cols = 2;

        final availW =
            constraints.maxWidth - padding * 2 - spacing * (cols - 1);
        final availH = constraints.maxHeight -
            padding * 2 -
            spacing * (rows - 1) -
            (_needsRotation ? dotsHeight : 0);

        final cardW = availW / cols;
        final cardH = availH / rows;
        final ratio = (cardW / cardH).clamp(0.7, 2.8);

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(padding),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: ratio,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (_, i) => ExamCard(session: sessions[i]),
                  ),
                ),
              ),
            ),
            if (_needsRotation)
              _PageDots(
                currentPage: _pageIndex,
                totalPages: _pageCount,
                onDotTap: (i) async {
                  _rotationTimer?.cancel();
                  await _fadeCtrl.reverse();
                  if (!mounted) return;
                  setState(() => _pageIndex = i);
                  await _fadeCtrl.forward();
                  _startRotation();
                },
                cs: cs,
              ),
          ],
        );
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onDotTap;
  final ColorScheme cs;

  const _PageDots({
    required this.currentPage,
    required this.totalPages,
    required this.onDotTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Seite ${currentPage + 1} von $totalPages  ·  wechselt automatisch',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.35),
                ),
          ),
          const SizedBox(width: 12),
          ...List.generate(totalPages, (i) {
            final active = i == currentPage;
            return GestureDetector(
              onTap: () => onDotTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: active ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_outlined,
                  size: 46, color: cs.primary.withOpacity(0.7)),
            ),
            const SizedBox(height: 28),
            Text(
              'Noch keine Kurse',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tippe auf „Kurs hinzufügen" und\nrichte die heutige Klausur ein.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.45),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
