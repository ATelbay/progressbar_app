import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.comingSoon,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
