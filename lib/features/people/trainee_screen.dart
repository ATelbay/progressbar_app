import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../placeholder_body.dart';

class TraineeScreen extends StatelessWidget {
  const TraineeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.traineeTitle)),
      body: const PlaceholderBody(),
    );
  }
}
