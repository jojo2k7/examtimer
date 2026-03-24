import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_session.dart';

class ExamProvider extends ChangeNotifier {
  final List<ExamSession> _sessions = [];
  final Queue<CompletionEvent> _completionQueue = Queue();
  Timer? _ticker;
  bool _loaded = false;

  static const String _kKey = 'klausurtimer_sessions_v1';

  ExamProvider() {
    _loadSessions();
  }

  bool get isLoaded => _loaded;
  List<ExamSession> get sessions => List.unmodifiable(_sessions);

  CompletionEvent? get nextCompletion =>
      _completionQueue.isEmpty ? null : _completionQueue.first;

  bool get hasAnySessions => _sessions.isNotEmpty;

  bool get canStartAll => _sessions.any(
        (s) => s.status == ExamStatus.idle || s.status == ExamStatus.paused,
      );

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final loaded = list
            .map((e) => ExamSession.fromJson(e as Map<String, dynamic>))
            .toList();
        _sessions.addAll(loaded);
        for (final s in _sessions) {
          if (s.status == ExamStatus.running) {
            _ensureTicker();
          }
        }
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  void _save() {
    SharedPreferences.getInstance().then((prefs) {
      final encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
      prefs.setString(_kKey, encoded);
    });
  }

  void addSession(ExamSession session) {
    session.phase = session.initialPhase;
    _sessions.add(session);
    _save();
    notifyListeners();
  }

  void updateSessionConfig(ExamSession updated) {
    final i = _indexOf(updated.id);
    if (i != -1) {
      if (updated.status == ExamStatus.idle) {
        updated.phase = updated.initialPhase;
      }
      _sessions[i] = updated;
      _save();
      notifyListeners();
    }
  }

  void removeSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    _completionQueue.removeWhere((e) => e.session.id == id);
    _checkTicker();
    _save();
    notifyListeners();
  }

  void startSession(String id) {
    final s = _find(id);
    if (s == null || s.status == ExamStatus.finished) return;
    if (s.status == ExamStatus.idle) {
      s.phase = s.initialPhase;
      s.phaseAccumulated = Duration.zero;
    }
    s.phaseStartedAt = DateTime.now();
    s.status = ExamStatus.running;
    _ensureTicker();
    _save();
    notifyListeners();
  }

  void pauseSession(String id) {
    final s = _find(id);
    if (s == null || s.status != ExamStatus.running) return;
    s.phaseAccumulated = s.phaseElapsed;
    s.phaseStartedAt = null;
    s.status = ExamStatus.paused;
    _checkTicker();
    _save();
    notifyListeners();
  }

  void resetSession(String id) {
    final s = _find(id);
    if (s == null) return;
    _completionQueue.removeWhere((e) => e.session.id == id);
    s.resetToIdle();
    _checkTicker();
    _save();
    notifyListeners();
  }

  void startAll() {
    for (final s in _sessions) {
      if (s.status == ExamStatus.idle || s.status == ExamStatus.paused) {
        if (s.status == ExamStatus.idle) {
          s.phase = s.initialPhase;
          s.phaseAccumulated = Duration.zero;
        }
        s.phaseStartedAt = DateTime.now();
        s.status = ExamStatus.running;
      }
    }
    _ensureTicker();
    _save();
    notifyListeners();
  }

  void dismissCompletion() {
    if (_completionQueue.isNotEmpty) {
      _completionQueue.removeFirst();
      notifyListeners();
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    for (final s in _sessions) {
      if (s.status != ExamStatus.running) continue;
      if (s.remaining > Duration.zero) continue;

      s.phaseAccumulated = s.currentPhaseDuration;
      s.phaseStartedAt = null;

      switch (s.phase) {
        case ExamPhase.toolFree:
          _completionQueue.addLast(CompletionEvent(s, CompletionType.toolFree));
          s.phase = ExamPhase.main;
          s.phaseAccumulated = Duration.zero;
          s.phaseStartedAt = DateTime.now();

        case ExamPhase.main:
          _completionQueue.addLast(CompletionEvent(s, CompletionType.main));
          if (s.hasNta) {
            s.phase = ExamPhase.nta;
            s.phaseAccumulated = Duration.zero;
            s.phaseStartedAt = DateTime.now();
          } else {
            s.status = ExamStatus.finished;
          }

        case ExamPhase.nta:
          _completionQueue.addLast(CompletionEvent(s, CompletionType.nta));
          s.status = ExamStatus.finished;
      }
    }
    _checkTicker();
    _save();
    notifyListeners();
  }

  void _checkTicker() {
    final hasRunning = _sessions.any((s) => s.status == ExamStatus.running);
    if (!hasRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  ExamSession? _find(String id) {
    final i = _indexOf(id);
    return i != -1 ? _sessions[i] : null;
  }

  int _indexOf(String id) => _sessions.indexWhere((s) => s.id == id);

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
