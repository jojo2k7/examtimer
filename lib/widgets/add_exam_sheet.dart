import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/exam_session.dart';
import '../providers/exam_provider.dart';

class AddExamSheet extends StatefulWidget {
  final ExamSession? existingSession;

  const AddExamSheet({super.key, this.existingSession});

  @override
  State<AddExamSheet> createState() => _AddExamSheetState();
}

class _AddExamSheetState extends State<AddExamSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _subjectCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _ntaCtrl;
  late final TextEditingController _toolFreeMinCtrl;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _toolFreeMessageCtrl;

  bool _hasNta = false;
  bool _hasToolFree = false;

  static const String _defaultCompletionMessage =
      'Bitte legen Sie Ihren Stift ab und bleiben Sie ruhig sitzen. '
      'Kommen Sie erst nach vorne, wenn Sie aufgerufen werden. '
      'Bitte nehmen Sie ausgeliehene Materialien wie Wörterbücher mit nach vorne '
      'und verhalten Sie sich rücksichtsvoll gegenüber den noch schreibenden Mitschülerinnen und Mitschülern.';

  static const String _defaultToolFreeMessage =
      'Der hilfsmittelfreie Teil ist beendet. '
      'Bitte legen Sie alle nicht erlaubten Hilfsmittel weg. '
      'Der Hauptteil der Klausur beginnt jetzt.';

  @override
  void initState() {
    super.initState();
    final s = widget.existingSession;
    _subjectCtrl = TextEditingController(text: s?.subject ?? '');
    _courseCtrl = TextEditingController(text: s?.courseName ?? '');
    _hoursCtrl =
        TextEditingController(text: (s?.baseDuration.inHours ?? 1).toString());
    _minutesCtrl = TextEditingController(
        text: (s?.baseDuration.inMinutes.remainder(60) ?? 30)
            .toString()
            .padLeft(2, '0'));
    _ntaCtrl = TextEditingController(text: s?.ntaMinutes.toString() ?? '30');
    _toolFreeMinCtrl = TextEditingController(
        text: (s?.toolFreeDuration?.inMinutes ?? 30).toString());
    _messageCtrl = TextEditingController(
        text: s?.completionMessage ?? _defaultCompletionMessage);
    _toolFreeMessageCtrl = TextEditingController(
        text: s?.toolFreeCompletionMessage ?? _defaultToolFreeMessage);
    _hasNta = s?.hasNta ?? false;
    _hasToolFree = s?.hasToolFree ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _subjectCtrl,
      _courseCtrl,
      _hoursCtrl,
      _minutesCtrl,
      _ntaCtrl,
      _toolFreeMinCtrl,
      _messageCtrl,
      _toolFreeMessageCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final h = int.tryParse(_hoursCtrl.text.trim()) ?? 0;
    final m = int.tryParse(_minutesCtrl.text.trim()) ?? 0;
    final baseDuration = Duration(hours: h, minutes: m);
    final ntaMin = _hasNta ? (int.tryParse(_ntaCtrl.text.trim()) ?? 0) : 0;
    final toolFreeMin =
        _hasToolFree ? (int.tryParse(_toolFreeMinCtrl.text.trim()) ?? 0) : 0;
    final toolFreeDuration =
        toolFreeMin > 0 ? Duration(minutes: toolFreeMin) : null;

    final provider = context.read<ExamProvider>();

    if (widget.existingSession != null) {
      final s = widget.existingSession!;
      s.subject = _subjectCtrl.text.trim();
      s.courseName = _courseCtrl.text.trim();
      s.baseDuration = baseDuration;
      s.ntaMinutes = ntaMin;
      s.toolFreeDuration = toolFreeDuration;
      s.completionMessage = _messageCtrl.text.trim();
      s.toolFreeCompletionMessage = _toolFreeMessageCtrl.text.trim();
      provider.updateSessionConfig(s);
    } else {
      provider.addSession(ExamSession(
        id: const Uuid().v4(),
        subject: _subjectCtrl.text.trim(),
        courseName: _courseCtrl.text.trim(),
        baseDuration: baseDuration,
        ntaMinutes: ntaMin,
        toolFreeDuration: toolFreeDuration,
        completionMessage: _messageCtrl.text.trim(),
        toolFreeCompletionMessage: _toolFreeMessageCtrl.text.trim(),
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.existingSession != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEditing ? 'Kurs bearbeiten' : 'Neuer Kurs',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEditing
                    ? 'Einstellungen für diesen Kurs anpassen.'
                    : 'Fach, Dauer und Hinweistexte einstellen.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 28),
              _SectionLabel(label: 'Fach *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'z.B. Mathematik, Deutsch, Englisch',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Bitte gib ein Fach ein.'
                    : null,
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Kursbezeichnung (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _courseCtrl,
                decoration: const InputDecoration(
                  hintText: 'z.B. LK 12a, GK 11b',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Prüfungsdauer *'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _hoursCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                        hintText: '1', suffixText: 'Std.'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Ungültig';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _minutesCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                        hintText: '30', suffixText: 'Min.'),
                    validator: (v) {
                      final h = int.tryParse(_hoursCtrl.text) ?? 0;
                      final m = int.tryParse(v ?? '');
                      if (m == null || m < 0 || m > 59) return '0–59';
                      if (h == 0 && m == 0) return 'Muss > 0 sein';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _ToggleSection(
                icon: Icons.lock_outline_rounded,
                title: 'Hilfsmittelfreier Teil',
                subtitle: 'Startet vor der Klausur – keine Hilfsmittel erlaubt',
                value: _hasToolFree,
                onChanged: (v) => setState(() => _hasToolFree = v),
                cs: cs,
              ),
              if (_hasToolFree) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _toolFreeMinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Dauer des hilfsmittelfreien Teils',
                    prefixIcon: Icon(Icons.timer_outlined),
                    suffixText: 'Min.',
                  ),
                  validator: (v) {
                    if (!_hasToolFree) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Muss größer als 0 sein';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _toolFreeMessageCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nachricht wenn Teil endet',
                    hintText:
                        'Was sollen die Schüler:innen nach dem hilfsmittelfreien Teil tun?',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ToggleSection(
                icon: Icons.more_time_rounded,
                title: 'Nachteilsausgleich (NTA)',
                subtitle: 'Schüler:innen erhalten Zusatzzeit',
                value: _hasNta,
                onChanged: (v) => setState(() => _hasNta = v),
                cs: cs,
              ),
              if (_hasNta) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ntaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Zusatzzeit',
                    prefixIcon: Icon(Icons.more_time_rounded),
                    suffixText: 'Min. extra',
                  ),
                  validator: (v) {
                    if (!_hasNta) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Muss größer als 0 sein';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              _SectionLabel(label: 'Nachricht bei Zeitablauf (Klausurende)'),
              const SizedBox(height: 4),
              Text(
                'Erscheint wenn die Hauptzeit abgelaufen ist.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurface.withOpacity(0.45)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Was sollen die Schüler:innen jetzt tun?',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      isEditing ? 'Änderungen speichern' : 'Kurs hinzufügen',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;

  const _ToggleSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: value ? cs.primary : cs.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(subtitle),
        contentPadding:
            const EdgeInsets.only(left: 16, right: 12, top: 4, bottom: 4),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
    );
  }
}
