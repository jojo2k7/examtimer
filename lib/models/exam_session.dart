enum ExamStatus { idle, running, paused, finished }

enum ExamPhase { toolFree, main, nta }

enum CompletionType { toolFree, main, nta }

class CompletionEvent {
  final ExamSession session;
  final CompletionType type;

  CompletionEvent(this.session, this.type);
}

class ExamSession {
  final String id;
  String subject;
  String courseName;
  Duration baseDuration;
  int ntaMinutes;
  Duration? toolFreeDuration;
  String completionMessage;
  String toolFreeCompletionMessage;

  ExamStatus status;
  ExamPhase phase;
  DateTime? phaseStartedAt;
  Duration phaseAccumulated;

  ExamSession({
    required this.id,
    required this.subject,
    this.courseName = '',
    required this.baseDuration,
    this.ntaMinutes = 0,
    this.toolFreeDuration,
    required this.completionMessage,
    String? toolFreeCompletionMessage,
    this.status = ExamStatus.idle,
    this.phase = ExamPhase.main,
    this.phaseStartedAt,
    Duration? phaseAccumulated,
  })  : phaseAccumulated = phaseAccumulated ?? Duration.zero,
        toolFreeCompletionMessage = toolFreeCompletionMessage ??
            'Der hilfsmittelfreie Teil ist beendet. '
                'Der Hauptteil der Klausur beginnt jetzt.';

  bool get hasNta => ntaMinutes > 0;

  bool get hasToolFree =>
      toolFreeDuration != null && toolFreeDuration!.inSeconds > 0;

  ExamPhase get initialPhase =>
      hasToolFree ? ExamPhase.toolFree : ExamPhase.main;

  Duration get currentPhaseDuration {
    switch (phase) {
      case ExamPhase.toolFree:
        return toolFreeDuration ?? Duration.zero;
      case ExamPhase.main:
        return baseDuration;
      case ExamPhase.nta:
        return Duration(minutes: ntaMinutes);
    }
  }

  Duration get phaseElapsed {
    if (status == ExamStatus.idle) return Duration.zero;
    if (phaseStartedAt == null) return phaseAccumulated;
    return phaseAccumulated + DateTime.now().difference(phaseStartedAt!);
  }

  Duration get remaining {
    final r = currentPhaseDuration - phaseElapsed;
    return r.isNegative ? Duration.zero : r;
  }

  Duration get totalRemaining {
    switch (phase) {
      case ExamPhase.toolFree:
        return remaining + baseDuration + Duration(minutes: ntaMinutes);
      case ExamPhase.main:
        return remaining + Duration(minutes: ntaMinutes);
      case ExamPhase.nta:
        return remaining;
    }
  }

  double get phaseProgress {
    if (currentPhaseDuration.inSeconds == 0) return 0.0;
    return (phaseElapsed.inSeconds / currentPhaseDuration.inSeconds)
        .clamp(0.0, 1.0);
  }

  void resetToIdle() {
    status = ExamStatus.idle;
    phase = initialPhase;
    phaseStartedAt = null;
    phaseAccumulated = Duration.zero;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'courseName': courseName,
        'baseDurationMinutes': baseDuration.inMinutes,
        'ntaMinutes': ntaMinutes,
        'toolFreeDurationMinutes': toolFreeDuration?.inMinutes,
        'completionMessage': completionMessage,
        'toolFreeCompletionMessage': toolFreeCompletionMessage,
        'status': status.name,
        'phase': phase.name,
        'phaseAccumulatedSeconds': phaseAccumulated.inSeconds,
        'phaseStartedAt': phaseStartedAt?.toIso8601String(),
      };

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    final tfMin = json['toolFreeDurationMinutes'] as int?;
    return ExamSession(
      id: json['id'] as String,
      subject: json['subject'] as String,
      courseName: json['courseName'] as String? ?? '',
      baseDuration:
          Duration(minutes: json['baseDurationMinutes'] as int? ?? 60),
      ntaMinutes: json['ntaMinutes'] as int? ?? 0,
      toolFreeDuration: tfMin != null ? Duration(minutes: tfMin) : null,
      completionMessage: json['completionMessage'] as String? ?? '',
      toolFreeCompletionMessage: json['toolFreeCompletionMessage'] as String?,
      status: ExamStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ExamStatus.idle,
      ),
      phase: ExamPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => ExamPhase.main,
      ),
      phaseAccumulated:
          Duration(seconds: json['phaseAccumulatedSeconds'] as int? ?? 0),
      phaseStartedAt: json['phaseStartedAt'] != null
          ? DateTime.parse(json['phaseStartedAt'] as String)
          : null,
    );
  }
}
