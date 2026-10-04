import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../placeholder_body.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.tabHistory)),
      body: const PlaceholderBody(),
    );
  }
}
