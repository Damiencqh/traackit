import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';

/// "TRAACK BOX ───────" style divider used on the home screen.
class SectionDivider extends StatelessWidget {
  final String label;
  const SectionDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.eyebrow(size: 12),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}
