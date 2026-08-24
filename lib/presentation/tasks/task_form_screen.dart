import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/enums.dart';
import '../mutation_result.dart';
import '../projects/project_providers.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'task_controller.dart';
import 'task_providers.dart';

/// Create a task (optionally pre-scoped to a project) or edit an existing one.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({this.taskId, this.initialProjectId, super.key});

  final String? taskId;
  final String? initialProjectId;

  bool get isEditing => taskId != null;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _projectId;
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  String? _assigneeId;
  DateTime? _dueDate;

  Map<String, String> _fieldErrors = {};
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _prefill(Task task) {
    if (_prefilled) return;
    _prefilled = true;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _projectId = task.projectId;
    _status = task.status;
    _priority = task.priority;
    _assigneeId = task.assigneeId;
    _dueDate = task.dueDate;
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit(Task? existing) async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final projectId = _projectId;
    if (projectId == null) {
      setState(() => _fieldErrors = {'project': 'Choose a project'});
      _formKey.currentState?.validate();
      return;
    }

    final controller = ref.read(taskControllerProvider.notifier);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final result = existing == null
        ? await controller.create(
            projectId: projectId,
            title: title,
            description: description,
            status: _status,
            priority: _priority,
            assigneeId: _assigneeId,
            dueDate: _dueDate,
          )
        : await controller.update(
            existing.copyWith(
              title: title,
              description: description,
              status: _status,
              priority: _priority,
              assigneeId: _assigneeId,
              clearAssignee: _assigneeId == null,
              dueDate: _dueDate,
              clearDueDate: _dueDate == null,
            ),
          );

    if (!mounted) return;

    switch (result) {
      case MutationSuccess():
        showAppSnackBar(
          context,
          existing == null ? 'Task created.' : 'Task updated.',
        );
        Navigator.of(context).pop();
      case MutationFailure(:final message, :final fieldErrors):
        setState(() => _fieldErrors = fieldErrors);
        _formKey.currentState?.validate();
        showAppSnackBar(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = ref.watch(taskControllerProvider);

    if (!widget.isEditing) return _buildForm(existing: null, isBusy: isBusy);

    final task = ref.watch(taskByIdProvider(widget.taskId!));
    return task.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(
          message: messageFor(error),
          onRetry: () => ref.invalidate(taskByIdProvider(widget.taskId!)),
        ),
      ),
      data: (data) {
        _prefill(data);
        return _buildForm(existing: data, isBusy: isBusy);
      },
    );
  }

  Widget _buildForm({required Task? existing, required bool isBusy}) {
    final projects = ref.watch(projectsProvider).valueOrNull ?? const [];
    final members = ref.watch(orgMembersProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(existing == null ? 'New task' : 'Edit task')),
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
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What needs to be done?',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: Validators.taskTitleMaxLength,
                      enabled: !isBusy,
                      validator: (value) =>
                          _fieldErrors['title'] ?? Validators.taskTitle(value),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add any useful detail',
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
                    const SizedBox(height: AppSpacing.md),

                    // Project is fixed once a task exists: moving a task
                    // between projects is out of scope for this app.
                    DropdownButtonFormField<String>(
                      initialValue: _projectId,
                      decoration: InputDecoration(
                        labelText: 'Project',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        errorText: _fieldErrors['project'],
                      ),
                      items: [
                        for (final project in projects)
                          DropdownMenuItem(
                            value: project.id,
                            child: Text(
                              project.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: isBusy || existing != null
                          ? null
                          : (value) => setState(() => _projectId = value),
                      validator: (value) =>
                          value == null ? 'Choose a project' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    DropdownButtonFormField<TaskStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        for (final status in TaskStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  status.icon,
                                  size: 18,
                                  color: status.color,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(status.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: isBusy
                          ? null
                          : (value) => setState(
                              () => _status = value ?? _status,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    DropdownButtonFormField<TaskPriority>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: [
                        for (final priority in TaskPriority.values.reversed)
                          DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(
                                  priority.icon,
                                  size: 18,
                                  color: priority.color,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(priority.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: isBusy
                          ? null
                          : (value) => setState(
                              () => _priority = value ?? _priority,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    DropdownButtonFormField<String?>(
                      initialValue: _assigneeId,
                      decoration: const InputDecoration(
                        labelText: 'Assignee',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        for (final member in members)
                          DropdownMenuItem(
                            value: member.user.id,
                            child: Text(
                              member.user.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _assigneeId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _DueDateField(
                      value: _dueDate,
                      enabled: !isBusy,
                      onPick: _pickDueDate,
                      onClear: () => setState(() => _dueDate = null),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton(
                      onPressed: isBusy ? null : () => _submit(existing),
                      child: isBusy
                          ? const ButtonSpinner()
                          : Text(
                              existing == null ? 'Create task' : 'Save changes',
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

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.value,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onPick : null,
      borderRadius: AppRadius.field,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due date',
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: value == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: enabled ? onClear : null,
                  tooltip: 'Clear due date',
                ),
          enabled: enabled,
        ),
        child: Text(
          value == null ? 'No due date' : Dates.full(value!),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: value == null ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
