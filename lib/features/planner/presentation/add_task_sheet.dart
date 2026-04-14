import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../family/providers/family_providers.dart';
import '../domain/task_category.dart';
import '../domain/task_model.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final int initialHour;
  final int initialMinute;
  final TaskModel? existingTask; // null = new task, non-null = editing

  const AddTaskSheet({
    super.key,
    this.initialHour = 8,
    this.initialMinute = 0,
    this.existingTask,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  late TextEditingController _titleController;
  late TaskCategory _category;
  String? _customCategoryName; // when category == custom
  late int _hour;
  late int _minute;
  late int _duration;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _category = t?.category ?? TaskCategory.exercise;
    _customCategoryName = t?.customCategoryName;
    _hour = t?.hour ?? widget.initialHour;
    _minute = t?.minute ?? widget.initialMinute;
    _duration = t?.duration ?? 60;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pickTemplate(String template) {
    _titleController.text = template;
  }

  Future<void> _addCustomCategoryDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'e.g. Music, Cooking, Meditation',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final appUser = ref.read(appUserProvider).value;
    if (appUser?.familyId != null) {
      try {
        await ref
            .read(familyRepositoryProvider)
            .addCustomCategory(appUser!.familyId!, name);
      } catch (_) {
        // ignore errors; still select locally
      }
    }
    setState(() {
      _category = TaskCategory.custom;
      _customCategoryName = name;
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your task a name!')),
      );
      return;
    }

    final task = widget.existingTask != null
        ? widget.existingTask!.copyWith(
            hour: _hour,
            minute: _minute,
            duration: _duration,
            title: title,
            category: _category,
            customCategoryName:
                _category == TaskCategory.custom ? _customCategoryName : null,
          )
        : TaskModel.create(
            hour: _hour,
            minute: _minute,
            duration: _duration,
            title: title,
            category: _category,
            customCategoryName:
                _category == TaskCategory.custom ? _customCategoryName : null,
          );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final templates = TaskTemplates.templates[_category] ?? [];
    final family = ref.watch(familyProvider).value;
    final customCategories = family?.customCategories ?? const [];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                widget.existingTask != null ? 'Edit Task' : 'Add Task',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 20),

              // Category picker
              Text('Category', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Preset categories (exclude `custom` from preset chips)
                  ...TaskCategory.values
                      .where((c) => c != TaskCategory.custom)
                      .map((cat) {
                    final selected =
                        _category == cat && _category != TaskCategory.custom;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              size: 16,
                              color: selected ? Colors.white : cat.color),
                          const SizedBox(width: 4),
                          Text(cat.displayName),
                        ],
                      ),
                      selected: selected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() {
                        _category = cat;
                        _customCategoryName = null;
                      }),
                    );
                  }),
                  // Family's custom categories
                  ...customCategories.map((name) {
                    final selected = _category == TaskCategory.custom &&
                        _customCategoryName == name;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.accent),
                          const SizedBox(width: 4),
                          Text(name),
                        ],
                      ),
                      selected: selected,
                      selectedColor: AppColors.accent,
                      labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() {
                        _category = TaskCategory.custom;
                        _customCategoryName = name;
                      }),
                    );
                  }),
                  // Add new category chip
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    onPressed: _addCustomCategoryDialog,
                    backgroundColor: AppColors.primary.withAlpha(20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick templates
              if (templates.isNotEmpty) ...[
                Text('Quick Pick', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: templates
                      .map((t) => ActionChip(
                            label: Text(t, style: const TextStyle(fontSize: 13)),
                            onPressed: () => _pickTemplate(t),
                            backgroundColor: _category.color.withAlpha(20),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Task name
              Text('Task Name', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'What will you do?',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // Start time picker (hour + minute)
              Text('Start Time', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: _hour, minute: _minute),
                          builder: (ctx, child) => MediaQuery(
                            data: MediaQuery.of(ctx)
                                .copyWith(alwaysUse24HourFormat: false),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          // Snap to nearest 15 min.
                          final snappedMinute =
                              ((picked.minute / 15).round() * 15) % 60;
                          final extraHour =
                              ((picked.minute / 15).round() * 15) >= 60
                                  ? 1
                                  : 0;
                          setState(() {
                            _hour = (picked.hour + extraHour) % 24;
                            _minute = snappedMinute;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Text('Tap to change',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Quick minute chips
              Wrap(
                spacing: 6,
                children: [0, 15, 30, 45].map((m) {
                  final selected = _minute == m;
                  return ChoiceChip(
                    label: Text(':${m.toString().padLeft(2, '0')}'),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _minute = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Duration slider
              Text('Duration: $_duration minutes', style: AppTextStyles.label),
              const SizedBox(height: 4),
              Slider(
                value: _duration.toDouble(),
                min: 15,
                max: 180,
                divisions: 11,
                label: '$_duration min',
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _duration = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('15 min', style: AppTextStyles.caption),
                  Text('3 hours', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 24),

              // Health indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _category.isHealthyByDefault
                      ? AppColors.accentGreen.withAlpha(20)
                      : AppColors.accentRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _category.isHealthyByDefault ? Icons.eco : Icons.warning,
                      color: _category.isHealthyByDefault
                          ? AppColors.accentGreen
                          : AppColors.accentRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _category.isHealthyByDefault
                            ? 'This is a healthy activity! Your creature will love it.'
                            : 'This counts as screen time. Balance it with healthy activities!',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existingTask != null
                      ? 'Save Changes'
                      : 'Add Task'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
