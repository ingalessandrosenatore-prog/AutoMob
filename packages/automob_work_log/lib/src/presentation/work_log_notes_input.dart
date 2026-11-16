import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'work_log_report_notes.dart';

class WorkLogNotesInput extends TextEditingController {
  String _problems = '';

  late final formatter = TextInputFormatter.withFunction(_formatEdit);

  String get manualNotes => _manualText(text);

  String _manualText(String value) => _problems.isEmpty
      ? value
      : value.substring(
          0,
          (value.length - _problems.length - 1).clamp(0, value.length),
        );

  void showNotes(String manual, String problems) {
    _problems = problems;
    final combined = appendResolvedProblemsNotes(manual, problems);
    if (text == combined) return;
    final previousSelection = selection;
    value = TextEditingValue(
      text: combined,
      selection: previousSelection.isValid
          ? previousSelection.copyWith(
              baseOffset: previousSelection.baseOffset.clamp(0, manual.length),
              extentOffset: previousSelection.extentOffset.clamp(
                0,
                manual.length,
              ),
            )
          : TextSelection.collapsed(offset: manual.length),
    );
  }

  TextEditingValue _formatEdit(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    if (_problems.isEmpty || before.text == after.text) return after;

    // Keep the generated suffix intact so deselecting a report can remove its
    // line without interpreting or deleting the text the user wrote.
    if (after.text.endsWith(_problems)) {
      final prefix = after.text.substring(
        0,
        after.text.length - _problems.length,
      );
      return prefix.isEmpty || prefix.endsWith('\n')
          ? after
          : after.copyWith(
              text: appendResolvedProblemsNotes(prefix, _problems),
            );
    }

    if (before.selection.start == 0 &&
        before.selection.end == before.text.length) {
      return after.copyWith(
        text: appendResolvedProblemsNotes(after.text, _problems),
      );
    }

    final manual = _manualText(before.text);
    if (after.text.startsWith(before.text)) {
      final inserted = after.text.substring(before.text.length);
      final updated = manual + inserted;
      return TextEditingValue(
        text: appendResolvedProblemsNotes(updated, _problems),
        selection: TextSelection.collapsed(offset: updated.length),
      );
    }
    return before.copyWith(
      selection: TextSelection.collapsed(offset: manual.length),
      composing: TextRange.empty,
    );
  }
}
