import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/care_items.dart';
import '../models/pet.dart';

const petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

Future<void> showPetEditor(
  BuildContext context,
  Pet? pet,
  Future<void> Function(String name, String type, int age) onSave,
) async {
  final nameController = TextEditingController(text: pet?.name ?? '');
  final ageController = TextEditingController(text: pet?.age.toString() ?? '');
  final formKey = GlobalKey<FormState>();
  var type = pet?.type ?? petTypes.first;
  await _showEditor(
    context,
    title: pet == null ? 'Add a pet' : 'Edit pet',
    formKey: formKey,
    controllers: [nameController, ageController],
    onSave: () => onSave(
      nameController.text.trim(),
      type,
      int.parse(ageController.text.trim()),
    ),
    child: StatefulBuilder(
      builder: (context, setState) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Pet name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Pet type'),
              items: petTypes
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                suffixText: 'years',
              ),
              validator: (value) {
                final age = int.tryParse(value?.trim() ?? '');
                if (age == null) return 'Enter an age from 0 to 100';
                if (age < 0 || age > 100) {
                  return 'Age must be between 0 and 100';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showFeedingEditor(
  BuildContext context,
  List<Pet> pets,
  Feeding? feeding,
  Future<void> Function(Feeding value) onSave,
) async {
  if (pets.isEmpty) return;
  final noteController = TextEditingController(text: feeding?.note ?? '');
  final formKey = GlobalKey<FormState>();
  var petId = feeding?.petId ?? pets.first.id;
  var time = TimeOfDay(
    hour: (feeding?.timeMinutes ?? 480) ~/ 60,
    minute: (feeding?.timeMinutes ?? 480) % 60,
  );
  var enabled = feeding?.isEnabled ?? true;
  await _showEditor(
    context,
    title: feeding == null ? 'Add feeding time' : 'Edit feeding time',
    formKey: formKey,
    controllers: [noteController],
    onSave: () => onSave(
      Feeding(
        id: feeding?.id ?? '',
        petId: petId,
        timeMinutes: time.hour * 60 + time.minute,
        note: noteController.text.trim(),
        isEnabled: enabled,
      ),
    ),
    child: StatefulBuilder(
      builder: (context, setState) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _petDropdown(pets, petId, (value) => setState(() => petId = value)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Feeding time'),
              subtitle: Text(time.format(context)),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (selected != null) setState(() => time = selected);
              },
            ),
            TextFormField(
              controller: noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Food / portion note',
                hintText: 'e.g. 1 cup of dry food',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder enabled'),
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showHealthEditor(
  BuildContext context,
  List<Pet> pets,
  HealthReminder? reminder,
  Future<void> Function(HealthReminder value) onSave,
) async {
  if (pets.isEmpty) return;
  final titleController = TextEditingController(text: reminder?.title ?? '');
  final notesController = TextEditingController(text: reminder?.notes ?? '');
  final formKey = GlobalKey<FormState>();
  var petId = reminder?.petId ?? pets.first.id;
  var date =
      reminder?.scheduledAt ?? DateTime.now().add(const Duration(days: 1));
  var time = TimeOfDay.fromDateTime(date);
  await _showEditor(
    context,
    title: reminder == null ? 'Add health reminder' : 'Edit appointment',
    formKey: formKey,
    controllers: [titleController, notesController],
    onSave: () => onSave(
      HealthReminder(
        id: reminder?.id ?? '',
        petId: petId,
        title: titleController.text.trim(),
        scheduledAt: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
        notes: notesController.text.trim(),
      ),
    ),
    child: StatefulBuilder(
      builder: (context, setState) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _petDropdown(pets, petId, (value) => setState(() => petId = value)),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Appointment title'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) setState(() => date = selected);
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(DateFormat('MMM d, yyyy').format(date)),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (selected != null) setState(() => time = selected);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(time.format(context)),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showGroomingEditor(
  BuildContext context,
  List<Pet> pets,
  GroomingLog? log,
  Future<void> Function(GroomingLog value) onSave,
) async {
  if (pets.isEmpty) return;
  final notesController = TextEditingController(text: log?.notes ?? '');
  final formKey = GlobalKey<FormState>();
  const groomingTypes = ['Bath', 'Brush', 'Nail trim', 'Haircut', 'Other'];
  var petId = log?.petId ?? pets.first.id;
  var type = log?.type ?? groomingTypes.first;
  var date = log?.date ?? DateTime.now();
  var repeatDays = log?.repeatDays;
  await _showEditor(
    context,
    title: log == null ? 'Log grooming' : 'Edit grooming',
    formKey: formKey,
    controllers: [notesController],
    onSave: () => onSave(
      GroomingLog(
        id: log?.id ?? '',
        petId: petId,
        type: type,
        date: date,
        notes: notesController.text.trim(),
        repeatDays: repeatDays,
      ),
    ),
    child: StatefulBuilder(
      builder: (context, setState) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _petDropdown(pets, petId, (value) => setState(() => petId = value)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: groomingTypes
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(date)),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selected != null) setState(() => date = selected);
              },
            ),
            TextFormField(
              controller: notesController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: repeatDays,
              decoration: const InputDecoration(labelText: 'Repeat reminder'),
              items: const [
                DropdownMenuItem<int?>(value: null, child: Text('No reminder')),
                DropdownMenuItem<int?>(value: 7, child: Text('Every week')),
                DropdownMenuItem<int?>(value: 14, child: Text('Every 2 weeks')),
                DropdownMenuItem<int?>(value: 30, child: Text('Every month')),
              ],
              onChanged: (value) => setState(() => repeatDays = value),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showTaskEditor(
  BuildContext context,
  List<Pet> pets,
  CareTask? task,
  Future<void> Function(CareTask value) onSave,
) async {
  if (pets.isEmpty) return;
  final titleController = TextEditingController(text: task?.title ?? '');
  final notesController = TextEditingController(text: task?.notes ?? '');
  final formKey = GlobalKey<FormState>();
  var petId = task?.petId ?? pets.first.id;
  await _showEditor(
    context,
    title: task == null ? 'Add care task' : 'Edit care task',
    formKey: formKey,
    controllers: [titleController, notesController],
    onSave: () => onSave(
      CareTask(
        id: task?.id ?? '',
        petId: petId,
        title: titleController.text.trim(),
        notes: notesController.text.trim(),
        isCompleted: task?.isCompleted ?? false,
        createdAt: task?.createdAt ?? DateTime.now(),
      ),
    ),
    child: StatefulBuilder(
      builder: (context, setState) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _petDropdown(pets, petId, (value) => setState(() => petId = value)),
            const SizedBox(height: 12),
            TextFormField(
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task',
                hintText: 'e.g. Evening walk',
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
      ),
    ),
  );
}

String? _requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

Widget _petDropdown(
  List<Pet> pets,
  String selectedId,
  ValueChanged<String> onChanged,
) => DropdownButtonFormField<String>(
  initialValue: selectedId,
  decoration: const InputDecoration(labelText: 'Pet'),
  items: pets
      .map(
        (pet) => DropdownMenuItem(
          value: pet.id,
          child: Text('${pet.name} · ${pet.type}'),
        ),
      )
      .toList(),
  onChanged: (value) {
    if (value != null) onChanged(value);
  },
);

Future<void> _showEditor(
  BuildContext context, {
  required String title,
  required GlobalKey<FormState> formKey,
  required List<TextEditingController> controllers,
  required Widget child,
  required Future<void> Function() onSave,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _SaveDialog(
      title: title,
      formKey: formKey,
      controllers: controllers,
      onSave: onSave,
      child: child,
    ),
  );
}

class _SaveDialog extends StatefulWidget {
  const _SaveDialog({
    required this.title,
    required this.formKey,
    required this.controllers,
    required this.child,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<TextEditingController> controllers;
  final Widget child;
  final Future<void> Function() onSave;

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Could not save. $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.child,
            if (_error != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );
}
