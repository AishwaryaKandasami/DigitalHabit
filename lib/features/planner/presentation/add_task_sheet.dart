import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/task_category.dart';
import '../domain/task_model.dart';

class AddTaskSheet extends StatefulWidget {
  final int initialHour;
  final TaskModel? existingTask; // null = new task, non-null = editing

  const AddTaskSheet({
    super.key,
    this.initialHour = 8,
    this.existingTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  late TaskCategory _category;
  late int _hour;
  late int _duration;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _category = t?.category ?? TaskCategory.exercise;
    _hour = t?.hour ?? widget.initialHour;
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
            duration: _duration,
            title: title,
            category: _category,
          )
        : TaskModel.create(
            hour: _hour,
            duration: _duration,
            title: title,
            category: _category,
          );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final templates = TaskTemplates.templates[_category] ?? [];

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
                children: TaskCategory.values.map((cat) {
                  final selected = _category == cat;
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
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
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

              // Time picker
              Text('Start Time', style: AppTextStyles.label),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 17, // 6 AM to 10 PM
                  itemBuilder: (context, index) {
                    final h = index + 6;
                    final selected = _hour == h;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => _hour = h),
                      ),
                    );
                  },
                ),
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
