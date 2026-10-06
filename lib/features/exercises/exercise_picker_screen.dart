import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exercise_catalog.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/step_button.dart';
import 'personal_exercises_provider.dart';

String areaName(AppLocalizations l10n, MuscleArea area) => switch (area) {
  MuscleArea.chest => l10n.groupChest,
  MuscleArea.back => l10n.groupBack,
  MuscleArea.legs => l10n.groupLegs,
  MuscleArea.shoulders => l10n.groupShoulders,
  MuscleArea.arms => l10n.groupArms,
  MuscleArea.core => l10n.groupCore,
};

String? equipmentName(AppLocalizations l10n, String? equipment) =>
    switch (equipment) {
      'dumbbell' => l10n.equipDumbbell,
      'barbell' => l10n.equipBarbell,
      'machine' => l10n.equipMachine,
      'cable' => l10n.equipCable,
      'body only' => l10n.equipBodyOnly,
      'e-z curl bar' => l10n.equipEzBar,
      'kettlebells' => l10n.equipKettlebell,
      _ => null,
    };

/// Picks one exercise from the user's catalog and returns it to the caller.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String _query = '';
  MuscleArea? _area;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.pb;
    final language = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(userCatalogProvider).value;
    final query = _query.trim().toLowerCase();
    final found = [
      for (final exercise in catalog?.values ?? const <Exercise>[])
        if ((_area == null || areaOf(exercise.muscleGroup) == _area) &&
            exercise.nameFor(language).toLowerCase().contains(query))
          exercise,
    ]..sort((a, b) => a.nameFor(language).compareTo(b.nameFor(language)));

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          bottom: false,
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
                Row(
                  spacing: PbSpace.s3,
                  children: [
                    StepButton(
                      icon: Icons.chevron_left,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      size: PbSize.touchMin,
                      onTap: () => context.pop(),
                    ),
                    Text(
                      l10n.pickerTitle,
                      style: PbText.title.copyWith(color: c.ink),
                    ),
                  ],
                ),
                TextField(
                  onChanged: (text) => setState(() => _query = text),
                  textInputAction: TextInputAction.search,
                  style: PbText.body.copyWith(color: c.ink),
                  decoration: InputDecoration(
                    hintText: l10n.pickerSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                SizedBox(
                  height: PbSize.touchMin,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      for (final area in [null, ...MuscleArea.values])
                        Padding(
                          padding: const EdgeInsets.only(right: PbSpace.s2),
                          child: PbPill(
                            selected: _area == area,
                            onTap: () => setState(() => _area = area),
                            child: Text(
                              area == null
                                  ? l10n.groupAll
                                  : areaName(l10n, area),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: catalog == null
                      ? const Center(child: CircularProgressIndicator())
                      : found.isEmpty
                      ? Center(
                          child: Text(
                            l10n.pickerNothing,
                            style: PbText.body.copyWith(color: c.inkMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: PbSpace.s6),
                          itemCount: found.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: PbSpace.s2),
                          itemBuilder: (context, index) {
                            final exercise = found[index];
                            final area = areaOf(exercise.muscleGroup);
                            final details = [
                              area == null
                                  ? exercise.muscleGroup
                                  : areaName(l10n, area),
                              ?equipmentName(l10n, exercise.equipment),
                            ].join(' · ');
                            return GlassCard(
                              onTap: () => context.pop(exercise),
                              child: Row(
                                spacing: PbSpace.s3,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.nameFor(language),
                                          style: PbText.bodyStrong.copyWith(
                                            color: c.ink,
                                          ),
                                        ),
                                        Text(
                                          details,
                                          style: PbText.caption.copyWith(
                                            color: c.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.add, color: c.ink),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
