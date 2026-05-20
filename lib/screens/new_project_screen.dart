import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../models/project.dart';
import '../models/template.dart';
import '../state/app_state.dart';
import '../widgets/template_overlay.dart';

/// Step 1 of project creation: pick a template and give it a name.
/// (Step 2 — a guided first capture — is a later milestone.)
class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  TemplateKind _selected = TemplateKind.face;
  final _name = TextEditingController(text: 'My new traack');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final project = Project(
      id: const Uuid().v4(),
      name: name,
      template: _selected,
      createdAt: DateTime.now(),
    );
    await ref.read(projectsProvider.notifier).addProject(project);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP 1 OF 2 · TEMPLATE', style: AppText.eyebrow()),
              const SizedBox(height: 8),
              Text('A new\ntraack.', style: AppText.display(size: 38)),
              const SizedBox(height: 10),
              Text(
                'Pick a shape to align with.',
                style: AppText.ui(size: 13, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    for (final t in TemplateKind.values)
                      _TemplateTile(
                        kind: t,
                        selected: t == _selected,
                        onTap: () => setState(() => _selected = t),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                style: AppText.serifBody(size: 15),
                decoration: InputDecoration(
                  labelText: 'NAME',
                  labelStyle: AppText.eyebrow(size: 9),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: _create,
                  child: Text(
                    'START TRAACKING',
                    style: AppText.ui(
                      size: 12,
                      color: AppColors.paper,
                      weight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final TemplateKind kind;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? const Color(0x114F6B3F)
                : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.lineSoft,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TemplateOverlay(
                  kind: kind,
                  color: selected ? AppColors.accent : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kind.label,
                style: AppText.serifBody(size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
