import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../placeholder_body.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.tabPeople)),
      body: const PlaceholderBody(),
    );
  }
}
