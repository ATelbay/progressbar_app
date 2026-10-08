import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/storage_status.dart';
import '../features/auth/auth_controller.dart';
import '../features/storage_status_providers.dart';
import '../l10n/app_localizations.dart';

/// Lives above the router: a refused completion or deletion must be visible
/// even after its screen has already closed following the local write.
class StorageWriteNotice extends ConsumerStatefulWidget {
  const StorageWriteNotice({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StorageWriteNotice> createState() => _StorageWriteNoticeState();
}

class _StorageWriteNoticeState extends ConsumerState<StorageWriteNotice> {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _notice;

  @override
  Widget build(BuildContext context) {
    ref.listen(uidProvider, (previous, next) {
      if (previous?.value != next.value) {
        _notice?.close();
        _notice = null;
        ref.read(storageWriteFailuresProvider.notifier).clear();
      }
    });
    ref.listen(storageWriteFailuresProvider, (_, failure) {
      if (failure == null) {
        _notice?.close();
        _notice = null;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            ref.read(storageWriteFailuresProvider) != failure ||
            ref.read(uidProvider).value != failure.userId) {
          return;
        }
        final l10n = AppLocalizations.of(context)!;
        final text = switch (failure.area) {
          StorageArea.workout => l10n.saveWorkoutRejected,
          StorageArea.program => l10n.saveProgramRejected,
          StorageArea.exercise => l10n.saveExerciseRejected,
        };
        _notice?.close();
        _notice = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            // A server refusal can arrive after leaving the gym. Keep it
            // visible until dismissed, instead of a fleeting toast.
            duration: const Duration(days: 1),
            action: SnackBarAction(
              label: MaterialLocalizations.of(context).okButtonLabel,
              onPressed: () =>
                  ref.read(storageWriteFailuresProvider.notifier).clear(),
            ),
          ),
        );
      });
    });
    return widget.child;
  }
}
