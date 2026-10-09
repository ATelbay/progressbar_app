import 'package:flutter/material.dart';

import '../theme.dart';
import 'glass_panel.dart';

/// Opens [child] as a glass sheet from the bottom, above the keyboard.
Future<T?> showPbSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: context.pb.scrim,
      isScrollControlled: true,
      builder: (_) => child,
    );

class PbSheet extends StatelessWidget {
  const PbSheet({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        PbSpace.s2,
        PbSpace.s2,
        PbSpace.s2,
        PbSpace.s2 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: GlassPanel(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PbSpace.s3,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// A sheet to pick one of a few options; returns the picked value.
class ChoiceSheet<T> extends StatelessWidget {
  const ChoiceSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<(T value, String label)> options;
  final T selected;

  @override
  Widget build(BuildContext context) {
    final c = context.pb;
    return PbSheet(
      children: [
        Text(title, style: PbText.heading.copyWith(color: c.ink)),
        for (final (value, label) in options)
          OutlinedButton(
            onPressed: () => Navigator.pop(context, (value,)),
            style: value == selected
                ? OutlinedButton.styleFrom(
                    foregroundColor: c.accentText,
                    side: BorderSide(color: c.accentText, width: 2),
                  )
                : null,
            child: Text(label),
          ),
      ],
    );
  }
}
