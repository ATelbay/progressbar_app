import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/workout_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../format.dart';

/// Shared read-only view of the first reorder snapshot.
class WorkoutOrderBlock extends StatefulWidget {
  const WorkoutOrderBlock(this.workout, {super.key});
  final Workout workout;
  @override
  State<WorkoutOrderBlock> createState() => _WorkoutOrderBlockState();
}

class _WorkoutOrderBlockState extends State<WorkoutOrderBlock> {
  bool _expanded = false;

  @override
  void didUpdateWidget(WorkoutOrderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different workout gets a fresh tile (its PageStorageKey changes),
    // which starts collapsed and notifies only when restored as expanded.
    if (oldWidget.workout.id != widget.workout.id) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final info = workoutOrderInfo(widget.workout);
    if (!info.changed) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!, c = context.pb;
    Widget list(
      String title,
      List<List<WorkoutExercise>> groups, {
      bool hint = false,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PbSize.inlineGap,
      children: [
        Text(title, style: PbText.label.copyWith(color: c.inkMuted)),
        if (hint)
          Text(
            l.workoutOriginalOrderHint,
            style: PbText.caption.copyWith(color: c.inkMuted),
          ),
        for (final (index, group) in groups.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PbSpace.s2,
            children: [
              SizedBox(
                width: PbSize.orderNumberWidth,
                child: Text(
                  '${index + 1}',
                  style: PbText.numSm.copyWith(color: c.inkMuted),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.map((e) => e.name).join(' + '),
                      style: PbText.caption.copyWith(color: c.inkMuted),
                    ),
                    if (group.any((e) => isOutsidePlan(widget.workout, e)))
                      PbChip(l.workoutOutsidePlan),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: ExpansionTile(
        key: PageStorageKey(('workout-order', widget.workout.id)),
        tilePadding: EdgeInsets.zero,
        minTileHeight: PbSize.touchMin,
        dense: true,
        visualDensity: VisualDensity.standard,
        childrenPadding: const EdgeInsets.only(bottom: PbSpace.s3),
        shape: const Border(),
        collapsedShape: const Border(),
        onExpansionChanged: (v) {
          // Restoring ExpansionTile from PageStorage can notify during layout.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _expanded != v) setState(() => _expanded = v);
          });
        },
        leading: Icon(
          Icons.swap_vert_rounded,
          color: c.accentText,
          size: PbSize.iconSm,
        ),
        title: Text(
          l.workoutOrderChanged,
          style: PbText.label.copyWith(color: c.ink),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: PbSpace.s1,
          children: [
            if (_expanded || info.plannedGroups.isNotEmpty)
              Text(
                _expanded ? l.workoutOrderHide : l.workoutOrderShow,
                style: PbText.label.copyWith(color: c.inkMuted),
              ),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: c.inkMuted,
              size: PbSize.iconSm,
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(PbSpace.s3),
            decoration: BoxDecoration(
              color: c.sunken,
              borderRadius: BorderRadius.circular(PbRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                if (info.plannedGroups.isNotEmpty)
                  list(l.workoutPlannedOrder, info.plannedGroups),
                if (info.showOriginal)
                  list(l.workoutOriginalOrder, info.originalGroups, hint: true),
                if (info.incomplete)
                  Text(
                    l.workoutOrderIncomplete,
                    style: PbText.caption.copyWith(color: c.inkMuted),
                  ),
                if (info.hasAddedLater)
                  Text(
                    l.workoutOrderAddedLater,
                    style: PbText.caption.copyWith(color: c.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
