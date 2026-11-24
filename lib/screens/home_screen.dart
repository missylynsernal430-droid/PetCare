import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/care_items.dart';
import '../models/pet.dart';
import '../providers/pet_care_provider.dart';
import '../widgets/edit_dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _taskFilter = 'All';

  static const _tabTitles = [
    'My pets',
    'Feeding',
    'Health',
    'Grooming',
    'Tasks',
  ];
  static const _tabIcons = [
    Icons.pets_rounded,
    Icons.restaurant_rounded,
    Icons.favorite_rounded,
    Icons.shower_rounded,
    Icons.checklist_rounded,
  ];

  Future<void> _addItem(PetCareProvider data) async {
    switch (_selectedTab) {
      case 0:
        await showPetEditor(context, null, (name, type, age) async {
          await data.savePet(null, name, type, age);
        });
        break;
      case 1:
        await showFeedingEditor(context, data.pets, null, (feeding) async {
          await data.saveFeeding(null, feeding);
        });
        break;
      case 2:
        await showHealthEditor(context, data.pets, null, (reminder) async {
          await data.saveHealth(null, reminder);
        });
        break;
      case 3:
        await showGroomingEditor(context, data.pets, null, (log) async {
          await data.saveGrooming(null, log);
        });
        break;
      case 4:
        await showTaskEditor(context, data.pets, null, (task) async {
          await data.saveTask(null, task);
        });
        break;
    }
  }

  Future<void> _editPet(PetCareProvider data, Pet pet) =>
      showPetEditor(context, pet, (name, type, age) async {
        await data.savePet(pet, name, type, age);
      });

  Future<void> _deletePet(PetCareProvider data, Pet pet) async {
    if (!await _confirmDelete(
      'Delete ${pet.name}?',
      'All of this pet’s care records will also be deleted.',
    )) {
      return;
    }
    await _runAction(() => data.deletePet(pet));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update PETCARE. $error')),
      );
    }
  }

  Future<bool> _confirmDelete(String title, String detail) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(detail),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = context.watch<PetCareProvider>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PETCARE',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              _tabTitles[_selectedTab],
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSelectedPage(data),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(data),
        icon: const Icon(Icons.add_rounded),
        label: Text(_selectedTab == 0 ? 'Add pet' : _addLabel),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: List.generate(
          _tabTitles.length,
          (index) => NavigationDestination(
            icon: Icon(_tabIcons[index]),
            label: _tabTitles[index],
          ),
        ),
      ),
    );
  }

  String get _addLabel => switch (_selectedTab) {
    1 => 'Feeding',
    2 => 'Appointment',
    3 => 'Grooming',
    _ => 'Task',
  };

  Widget _buildSelectedPage(PetCareProvider data) => switch (_selectedTab) {
    0 => _buildPets(data),
    1 => _buildFeedings(data),
    2 => _buildHealth(data),
    3 => _buildGrooming(data),
    _ => _buildTasks(data),
  };

  Widget _buildPets(PetCareProvider data) {
    if (data.pets.isEmpty) {
      return _EmptyState(
        icon: Icons.pets_rounded,
        title: 'No pets yet',
        message: 'Add your first furry, feathered, or floppy friend.',
        actionLabel: 'Add your first pet',
        onAction: () => _addItem(data),
      );
    }
    final pendingTasks = data.careTasks
        .where((task) => !task.isCompleted)
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
      children: [
        _WelcomeCard(petCount: data.pets.length, pendingTasks: pendingTasks),
        const SizedBox(height: 24),
        _SectionHeading(
          title: 'Your companions',
          subtitle:
              '${data.pets.length} ${data.pets.length == 1 ? 'pet' : 'pets'} in your care',
        ),
        const SizedBox(height: 12),
        ...data.pets.map(
          (pet) => _PetCard(
            pet: pet,
            lastGrooming: data.lastGrooming(pet.id),
            onEdit: () => _editPet(data, pet),
            onDelete: () => _deletePet(data, pet),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedings(PetCareProvider data) {
    if (data.pets.isEmpty) return _needPet(data);
    final items = [...data.feedings]
      ..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.restaurant_rounded,
        title: 'No feeding times',
        message: 'Set a daily routine and we’ll remind you when it’s mealtime.',
        actionLabel: 'Add feeding time',
        onAction: () => _addItem(data),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
      children: [
        const _SectionHeading(
          title: 'Daily meals',
          subtitle: 'A little routine goes a long way.',
        ),
        const SizedBox(height: 14),
        ...items.map(
          (feeding) => _CareCard(
            icon: Icons.restaurant_rounded,
            accent: const Color(0xFFE59B45),
            title: _formatMinutes(feeding.timeMinutes),
            subtitle:
                '${data.petName(feeding.petId)}${feeding.note.isEmpty ? '' : ' · ${feeding.note}'}',
            trailing: Switch(
              value: feeding.isEnabled,
              onChanged: (value) =>
                  _runAction(() => data.toggleFeeding(feeding, value)),
            ),
            onEdit: () => showFeedingEditor(
              context,
              data.pets,
              feeding,
              (value) => data.saveFeeding(feeding, value),
            ),
            onDelete: () async {
              if (await _confirmDelete(
                'Delete feeding time?',
                'This daily reminder will be removed.',
              )) {
                await _runAction(() => data.deleteFeeding(feeding));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealth(PetCareProvider data) {
    if (data.pets.isEmpty) return _needPet(data);
    final now = DateTime.now();
    final upcoming =
        data.healthReminders
            .where((item) => !item.scheduledAt.isBefore(now))
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past =
        data.healthReminders
            .where((item) => item.scheduledAt.isBefore(now))
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    if (upcoming.isEmpty && past.isEmpty) {
      return _EmptyState(
        icon: Icons.favorite_rounded,
        title: 'No appointments yet',
        message: 'Keep vet visits and health checkups all in one place.',
        actionLabel: 'Add appointment',
        onAction: () => _addItem(data),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
      children: [
        const _SectionHeading(
          title: 'Health & wellness',
          subtitle: 'Appointments with a reminder one hour before.',
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _GroupLabel('UPCOMING'),
          const SizedBox(height: 8),
          ...upcoming.map((item) => _healthCard(data, item)),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _GroupLabel('PAST VISITS'),
          const SizedBox(height: 8),
          ...past.map((item) => _healthCard(data, item, isPast: true)),
        ],
      ],
    );
  }

  Widget _healthCard(
    PetCareProvider data,
    HealthReminder reminder, {
    bool isPast = false,
  }) => _CareCard(
    icon: Icons.medical_services_rounded,
    accent: const Color(0xFFDE8179),
    title: reminder.title,
    subtitle:
        '${data.petName(reminder.petId)} · ${DateFormat('EEE, MMM d · h:mm a').format(reminder.scheduledAt)}${reminder.notes.isEmpty ? '' : '\n${reminder.notes}'}',
    faded: isPast,
    onEdit: () => showHealthEditor(
      context,
      data.pets,
      reminder,
      (value) => data.saveHealth(reminder, value),
    ),
    onDelete: () async {
      if (await _confirmDelete(
        'Delete appointment?',
        'This health reminder will be removed.',
      )) {
        await _runAction(() => data.deleteHealth(reminder));
      }
    },
  );

  Widget _buildGrooming(PetCareProvider data) {
    if (data.pets.isEmpty) return _needPet(data);
    final logs = [...data.groomingLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty) {
      return _EmptyState(
        icon: Icons.shower_rounded,
        title: 'No grooming logged',
        message: 'Keep track of baths, brush-outs, nail trims, and more.',
        actionLabel: 'Log grooming',
        onAction: () => _addItem(data),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
      children: [
        const _SectionHeading(
          title: 'Grooming journal',
          subtitle: 'A fresh coat and a little extra love.',
        ),
        const SizedBox(height: 14),
        ...logs.map(
          (log) => _CareCard(
            icon: Icons.shower_rounded,
            accent: const Color(0xFF60AFA1),
            title: log.type,
            subtitle:
                '${data.petName(log.petId)} · ${DateFormat('MMM d, yyyy').format(log.date)}${log.notes.isEmpty ? '' : '\n${log.notes}'}${log.repeatDays == null ? '' : '\nRepeats every ${log.repeatDays} days'}',
            onEdit: () => showGroomingEditor(
              context,
              data.pets,
              log,
              (value) => data.saveGrooming(log, value),
            ),
            onDelete: () async {
              if (await _confirmDelete(
                'Delete grooming log?',
                'This activity will be removed.',
              )) {
                await _runAction(() => data.deleteGrooming(log));
              }
            },
          ),
        ),
        const SizedBox(height: 10),
        const _GroupLabel('LAST GROOMED'),
        const SizedBox(height: 8),
        ...data.pets.map((pet) {
          final last = data.lastGrooming(pet.id);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: const CircleAvatar(
              child: Icon(Icons.pets_rounded, size: 18),
            ),
            title: Text(pet.name),
            trailing: Text(
              last == null
                  ? 'Not logged yet'
                  : DateFormat('MMM d, yyyy').format(last),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTasks(PetCareProvider data) {
    if (data.pets.isEmpty) return _needPet(data);
    final tasks = [...data.careTasks]
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    final filtered = tasks
        .where(
          (task) => switch (_taskFilter) {
            'Pending' => !task.isCompleted,
            'Completed' => task.isCompleted,
            _ => true,
          },
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
      children: [
        const _SectionHeading(
          title: 'Little care things',
          subtitle: 'One kind thing at a time.',
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'All', label: Text('All')),
            ButtonSegment(value: 'Pending', label: Text('Pending')),
            ButtonSegment(value: 'Completed', label: Text('Done')),
          ],
          selected: {_taskFilter},
          onSelectionChanged: (selection) =>
              setState(() => _taskFilter = selection.first),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _InlineEmpty(
            icon: Icons.check_circle_outline_rounded,
            title: tasks.isEmpty ? 'No care tasks' : 'Nothing in this filter',
            message: tasks.isEmpty
                ? 'Add a walk, litter clean, or medicine reminder.'
                : 'Try another filter to see your tasks.',
          )
        else
          ...filtered.map((task) => _taskCard(data, task)),
      ],
    );
  }

  Widget _taskCard(PetCareProvider data, CareTask task) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) =>
                _runAction(() => data.toggleTask(task, value ?? false)),
          ),
          Expanded(
            child: InkWell(
              onTap: () => showTaskEditor(
                context,
                data.pets,
                task,
                (value) => data.saveTask(task, value),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${data.petName(task.petId)}${task.notes.isEmpty ? '' : ' · ${task.notes}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await showTaskEditor(
                  context,
                  data.pets,
                  task,
                  (updated) => data.saveTask(task, updated),
                );
              } else if (await _confirmDelete(
                'Delete this task?',
                'The task will be removed from your list.',
              )) {
                await _runAction(() => data.deleteTask(task));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _needPet(PetCareProvider data) => _EmptyState(
    icon: Icons.pets_rounded,
    title: 'Add a pet first',
    message: 'Care schedules are organized around each pet.',
    actionLabel: 'Add a pet',
    onAction: () => showPetEditor(context, null, (name, type, age) async {
      await data.savePet(null, name, type, age);
    }),
  );

  String _formatMinutes(int minutes) {
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return time.format(context);
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.petCount, required this.pendingTasks});

  final int petCount;
  final int pendingTasks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.tertiary, 0.42)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care that feels\nlike a walk in the park.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$petCount ${petCount == 1 ? 'little companion' : 'little companions'} · $pendingTasks care ${pendingTasks == 1 ? 'task' : 'tasks'} to do',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.wb_sunny_rounded,
            size: 50,
            color: colors.onPrimary.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.lastGrooming,
    required this.onEdit,
    required this.onDelete,
  });

  final Pet pet;
  final DateTime? lastGrooming;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, tint) = switch (pet.type.toLowerCase()) {
      'dog' => (Icons.pets_rounded, const Color(0xFFE59B45)),
      'cat' => (Icons.cruelty_free_rounded, const Color(0xFF9B86C6)),
      'bird' => (Icons.flutter_dash_rounded, const Color(0xFF58A9A1)),
      'rabbit' => (Icons.cruelty_free_rounded, const Color(0xFFE17D82)),
      _ => (Icons.favorite_rounded, colors.primary),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: tint.withValues(alpha: 0.14),
              child: Icon(icon, color: tint, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pet.type} · ${pet.age} ${pet.age == 1 ? 'year' : 'years'} old',
                  ),
                  if (lastGrooming != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Last groomed ${DateFormat('MMM d').format(lastGrooming!)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit profile')),
                PopupMenuItem(value: 'delete', child: Text('Delete pet')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  const _CareCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onEdit,
    this.onDelete,
    this.faded = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool faded;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: faded ? 0.08 : 0.15),
            child: Icon(icon, color: accent.withValues(alpha: faded ? 0.6 : 1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: faded
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onEdit != null && onDelete != null)
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit!() : onDelete!(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 1.3,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, size: 36, color: colors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
    child: Column(
      children: [
        Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 5),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
