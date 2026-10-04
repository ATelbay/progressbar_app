import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../placeholder_body.dart';

class ProgramBuilderScreen extends StatelessWidget {
  const ProgramBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.programBuilderTitle),
      ),
      body: const PlaceholderBody(),
    );
  }
}
