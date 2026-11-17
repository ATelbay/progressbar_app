import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exercise_catalog.dart';
import '../../domain/progress_logic.dart';
import '../../l10n/app_localizations.dart';
import '../../router.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../format.dart';
import 'progress_chart.dart';
import 'progress_providers.dart';

/// Every exercise with its latest result and how it changed; a tap opens
/// its chart.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final exercises = ref.watch(progressOverviewProvider).value;
    final found = [
      for (final exercise in exercises ?? const <ExerciseProgress>[])
        if (matchesSearch(exercise.name, _query)) exercise,
    ];

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PbSpace.s4,
              PbSpace.s4,
              PbSpace.s4,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s3,
              children: [
                Text(
                  l10n.tabProgress,
                  style: PbText.title.copyWith(color: c.ink),
                ),
                if (exercises == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (exercises.isEmpty)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              PbSpace.s4,
                              0,
                              PbSpace.s4,
                              PbSpace.s6,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: PbSpace.s3,
                              children: [
                                const EmptyProgressChart(),
                                Text(
                                  l10n.progressEmptyTitle,
                                  style: PbText.heading.copyWith(color: c.ink),
                                ),
                                Text(
                                  l10n.progressEmptyText,
                                  style: PbText.body.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => context.go(Routes.home),
                                  child: Text(l10n.historyToPrograms),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _search,
                    onChanged: (text) => setState(() => _query = text),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.progressSearch,
                      prefixIcon: const Icon(
                        Icons.search,
                        size: PbSize.iconSearch,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.close,
                                size: PbSize.iconSearch,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: found.isEmpty
                        ? SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: PbSpace.s6,
                                horizontal: PbSpace.s4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: PbSpace.s1,
                                children: [
                                  Text(
                                    l10n.progressNothingFound,
                                    style: PbText.bodyStrong.copyWith(
                                      color: c.ink,
                                    ),
                                  ),
                                  Text(
                                    l10n.progressNothingFoundHint,
                                    style: PbText.caption.copyWith(
                                      color: c.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: PbSpace.s4),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: found.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: PbSpace.s2),
                            itemBuilder: (context, index) =>
                                _ExerciseRow(found[index]),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Жим лёжа · 60 кг × 10» on the left; «≈ 80 кг», a small line and the
/// change on the right.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(this.exercise);

  final ExerciseProgress exercise;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    final points = exercise.points;
    final last = points.last;
    final best = pointSet(context, last);
    final change = progressChange(context, points);
    return GlassCard(
      onTap: () => context.go(Routes.progressOf(exercise.exerciseId)),
      padding: const EdgeInsets.all(PbSpace.s4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PbSpace.s1,
            children: [
              Text(
                exercise.name,
                style: PbText.bodyStrong.copyWith(color: c.ink),
              ),
              Text(
                (best ?? pointValue(context, last)).text,
                style: PbText.caption.copyWith(color: c.inkMuted),
              ),
            ],
          );
          final value = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: PbSize.inlineGap,
            children: [
              ProgressValue(
                last,
                style: PbText.numMd,
                approxStyle: PbText.numSm,
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: PbSpace.s2,
                runSpacing: PbSpace.s1,
                children: [
                  Sparkline(points),
                  if (change != null)
                    PbChip(
                      change.text,
                      color: change.down
                          ? c.warning
                          : points.last.value == points.first.value
                          ? c.inkMuted
                          : c.success,
                    ),
                ],
              ),
            ],
          );
          if (MediaQuery.textScalerOf(context).scale(1) > 1.35) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PbSpace.s2,
              children: [title, value],
            );
          }
          return Row(
            spacing: PbSpace.s3,
            children: [
              Expanded(child: title),
              value,
            ],
          );
        },
      ),
    );
  }
}
