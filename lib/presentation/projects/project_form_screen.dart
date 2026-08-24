import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../mutation_result.dart';
import 'project_controller.dart';
import 'project_providers.dart';

/// Create (no [projectId]) or edit an existing project.
class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({this.projectId, super.key});

  final String? projectId;

  bool get isEditing => projectId != null;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Server-side field errors, merged into the validators on the next pass.
  Map<String, String> _fieldErrors = {};
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefill(Project project) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = project.name;
    _descriptionController.text = project.description;
  }

  Future<void> _submit(Project? existing) async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(projectControllerProvider.notifier);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final result = existing == null
        ? await controller.create(name: name, description: description)
        : await controller.update(
            existing.copyWith(name: name, description: description),
          );

    if (!mounted) return;

    switch (result) {
      case MutationSuccess():
        showAppSnackBar(
          context,
          existing == null ? 'Project created.' : 'Project updated.',
        );
        Navigator.of(context).pop();
      case MutationFailure(:final message, :final fieldErrors):
        setState(() => _fieldErrors = fieldErrors);
        // Re-run validation so field-level server errors appear inline.
        _formKey.currentState?.validate();
        showAppSnackBar(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(projectControllerProvider);

    if (!widget.isEditing) {
      return _buildScaffold(existing: null, isBusy: isBusy);
    }

    final project = ref.watch(projectByIdProvider(widget.projectId!));
    return project.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(
          message: messageFor(error),
          onRetry: () => ref.invalidate(projectByIdProvider(widget.projectId!)),
        ),
      ),
      data: (data) {
        _prefill(data);
        return _buildScaffold(existing: data, isBusy: isBusy);
      },
    );
  }

  Widget _buildScaffold({required Project? existing, required bool isBusy}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'New project' : 'Edit project'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                        hintText: 'e.g. Website Relaunch',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: Validators.projectNameMaxLength,
                      enabled: !isBusy,
                      validator: (value) =>
                          _fieldErrors['name'] ?? Validators.projectName(value),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this project about?',
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      maxLength: Validators.descriptionMaxLength,
                      enabled: !isBusy,
                      validator: (value) =>
                          _fieldErrors['description'] ??
                          Validators.description(value),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    FilledButton(
                      onPressed: isBusy ? null : () => _submit(existing),
                      child: isBusy
                          ? const ButtonSpinner()
                          : Text(
                              existing == null
                                  ? 'Create project'
                                  : 'Save changes',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
