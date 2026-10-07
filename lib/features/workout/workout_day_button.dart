import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../theme.dart';

/// The day a workout counts for: quiet until touched, then the system
/// calendar. A day later than today cannot be picked.
class WorkoutDayButton extends StatelessWidget {
  const WorkoutDayButton({
    super.key,
    required this.day,
    required this.onPicked,
  });

  final DateTime day;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = !DateTime(day.year, day.month, day.day).isBefore(today);
    final label = isToday
        ? l10n.dayToday(DateFormat.MMMMd(locale).format(day))
        : day.year == now.year
        ? DateFormat.MMMMEEEEd(locale).format(day)
        : DateFormat.yMMMMd(locale).format(day);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: isToday ? today : day,
            firstDate: DateTime(now.year - 5),
            lastDate: today,
            helpText: l10n.dayPickerTitle,
          );
          if (picked != null) onPicked(picked);
        },
        style: TextButton.styleFrom(
          foregroundColor: c.inkMuted,
          minimumSize: const Size(0, PbSize.touchMin),
          padding: EdgeInsets.zero,
          textStyle: PbText.caption,
        ),
        icon: const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text(label),
      ),
    );
  }
}
