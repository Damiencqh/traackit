import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../models/project.dart';

/// One row in the Traack Box list on the home screen.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onCapture;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final hasToday = project.hasPhotoToday;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lineSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: AppText.serifBody(size: 16.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${project.daysIn} days in',
                        style: AppText.ui(
                          size: 11.5,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (hasToday)
                  const _UpdatedPill()
                else
                  _AddProgressButton(onTap: onCapture),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProgressButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProgressButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.accent),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text('ADD PROGRESS', style: AppText.button()),
      ),
    );
  }
}

class _UpdatedPill extends StatelessWidget {
  const _UpdatedPill();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x2E7C8E6A),
                blurRadius: 0,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'UPDATED',
          style: AppText.ui(
            size: 10.5,
            color: AppColors.inkSoft,
            weight: FontWeight.w600,
            letterSpacing: 1.05,
          ),
        ),
      ],
    );
  }
}
