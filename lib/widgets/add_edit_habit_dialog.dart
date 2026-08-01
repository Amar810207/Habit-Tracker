import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class AddEditHabitDialog extends StatefulWidget {
  final Habit? habit;

  const AddEditHabitDialog({super.key, this.habit});

  @override
  State<AddEditHabitDialog> createState() => _AddEditHabitDialogState();
}

class _AddEditHabitDialogState extends State<AddEditHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _selectedIconCode;

  // Available Category Icons
  final List<IconData> _categoryIcons = const [
    Icons.water_drop_rounded,
    Icons.fitness_center_rounded,
    Icons.menu_book_rounded,
    Icons.bedtime_rounded,
    Icons.self_improvement_rounded,
    Icons.code_rounded,
    Icons.directions_run_rounded,
    Icons.pedal_bike_rounded,
    Icons.directions_walk_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.check_circle_outline_rounded,
    Icons.brush_rounded,
    Icons.music_note_rounded,
    Icons.savings_rounded,
    Icons.language_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _selectedIconCode = widget.habit?.iconCodePoint ?? Icons.star.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<HabitProvider>(context, listen: false);
      if (widget.habit == null) {
        provider.addHabit(_nameController.text, _selectedIconCode);
      } else {
        provider.editHabit(widget.habit!.id, _nameController.text, _selectedIconCode);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Habit' : 'Create New Habit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Morning Run, Read Book...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Category Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Category Icon Selector
              SizedBox(
                height: 140,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _categoryIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _categoryIcons[index];
                    final isSelected = icon.codePoint == _selectedIconCode;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIconCode = icon.codePoint;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Create Habit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
