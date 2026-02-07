import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/activity.dart';
import '../providers/activity_provider.dart';

class EditInstanceScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String instanceId;
  final EditScope scope;

  const EditInstanceScreen({
    super.key,
    required this.teamId,
    required this.instanceId,
    required this.scope,
  });

  @override
  ConsumerState<EditInstanceScreen> createState() => _EditInstanceScreenState();
}

class _EditInstanceScreenState extends ConsumerState<EditInstanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;
  bool _hasInitialized = false;

  // Track which fields have been changed
  String? _originalTitle;
  String? _originalLocation;
  String? _originalDescription;
  String? _originalStartTime;
  String? _originalEndTime;
  DateTime? _originalDate;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromInstance(ActivityInstance instance) {
    if (_hasInitialized) return;
    _hasInitialized = true;

    _titleController.text = instance.title ?? '';
    _locationController.text = instance.location ?? '';
    _descriptionController.text = instance.description ?? '';
    _date = instance.date;

    if (instance.startTime != null) {
      _startTime = _parseTimeString(instance.startTime!);
    }
    if (instance.endTime != null) {
      _endTime = _parseTimeString(instance.endTime!);
    }

    // Store originals for comparison
    _originalTitle = instance.title;
    _originalLocation = instance.location;
    _originalDescription = instance.description;
    _originalStartTime = instance.startTime;
    _originalEndTime = instance.endTime;
    _originalDate = instance.date;
  }

  TimeOfDay? _parseTimeString(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  Future<void> _selectDate() async {
    if (widget.scope != EditScope.single) return; // Only for single edits

    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          (_startTime?.replacing(hour: (_startTime!.hour + 1) % 24) ??
              const TimeOfDay(hour: 20, minute: 0)),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _hasChanges() {
    final newTitle = _titleController.text.trim();
    final newLocation = _locationController.text.trim();
    final newDescription = _descriptionController.text.trim();
    final newStartTime = _startTime != null ? _formatTimeOfDay(_startTime!) : null;
    final newEndTime = _endTime != null ? _formatTimeOfDay(_endTime!) : null;

    if (newTitle != (_originalTitle ?? '')) return true;
    if (newLocation != (_originalLocation ?? '')) return true;
    if (newDescription != (_originalDescription ?? '')) return true;
    if (newStartTime != _originalStartTime) return true;
    if (newEndTime != _originalEndTime) return true;
    if (widget.scope == EditScope.single && _date != _originalDate) return true;

    return false;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges()) {
      context.pop();
      return;
    }

    setState(() => _isLoading = true);

    // Only send changed values
    final newTitle = _titleController.text.trim();
    final newLocation = _locationController.text.trim();
    final newDescription = _descriptionController.text.trim();
    final newStartTime = _startTime != null ? _formatTimeOfDay(_startTime!) : null;
    final newEndTime = _endTime != null ? _formatTimeOfDay(_endTime!) : null;

    final result = await ref.read(editInstanceProvider.notifier).editInstance(
          instanceId: widget.instanceId,
          teamId: widget.teamId,
          scope: widget.scope,
          title: newTitle != (_originalTitle ?? '') ? newTitle : null,
          location: newLocation != (_originalLocation ?? '') ? newLocation : null,
          description: newDescription != (_originalDescription ?? '') ? newDescription : null,
          startTime: newStartTime != _originalStartTime ? newStartTime : null,
          endTime: newEndTime != _originalEndTime ? newEndTime : null,
          date: widget.scope == EditScope.single && _date != _originalDate ? _date : null,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result != null) {
        final message = widget.scope == EditScope.single
            ? 'Aktivitet oppdatert'
            : '${result.affectedCount} aktiviteter oppdatert';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        context.pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke oppdatere aktivitet')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instanceAsync = ref.watch(instanceDetailProvider(widget.instanceId));
    final dateFormat = DateFormat('EEEE d. MMMM yyyy', 'nb_NO');
    final theme = Theme.of(context);

    final scopeDescription = widget.scope == EditScope.single
        ? 'Kun denne aktiviteten endres'
        : 'Denne og alle fremtidige aktiviteter i serien endres';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rediger aktivitet'),
      ),
      body: instanceAsync.when2(
        onRetry: () => ref.invalidate(instanceDetailProvider(widget.instanceId)),
        data: (instance) {
          _initializeFromInstance(instance);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Scope indicator
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          widget.scope == EditScope.single
                              ? Icons.event
                              : Icons.repeat,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.scope.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                scopeDescription,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Series info
                if (instance.seriesInfo != null && instance.seriesInfo!.isPartOfSeries) ...[
                  Text(
                    'Del av serie: ${instance.seriesInfo!.positionText} (${instance.seriesInfo!.recurrenceType.displayName})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Detached warning
                if (instance.isDetached) ...[
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_off,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Denne aktiviteten er allerede løsrevet fra serien',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Tittel',
                    suffixIcon: instance.titleOverride != null
                        ? Tooltip(
                            message: 'Har egendefinert verdi',
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vennligst skriv inn en tittel';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date (only for single scope)
                if (widget.scope == EditScope.single) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Dato'),
                    subtitle: Text(_date != null ? dateFormat.format(_date!) : 'Ikke satt'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (instance.dateOverride != null)
                          Tooltip(
                            message: 'Har egendefinert dato',
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: _selectDate,
                  ),
                  const Divider(),
                ],

                // Time
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time),
                        title: const Text('Fra'),
                        subtitle: Text(
                          _startTime != null ? _formatTimeOfDay(_startTime!) : 'Ikke satt',
                        ),
                        onTap: _selectStartTime,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Til'),
                        subtitle: Text(
                          _endTime != null ? _formatTimeOfDay(_endTime!) : 'Ikke satt',
                        ),
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                ),
                if (instance.startTimeOverride != null || instance.endTimeOverride != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      'Har egendefinerte tidspunkter',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const Divider(),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Sted (valgfritt)',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: instance.locationOverride != null
                        ? Tooltip(
                            message: 'Har egendefinert verdi',
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Beskrivelse (valgfritt)',
                    alignLabelWithHint: true,
                    suffixIcon: instance.descriptionOverride != null
                        ? Tooltip(
                            message: 'Har egendefinert verdi',
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Warning for "this and future"
                if (widget.scope == EditScope.thisAndFuture) ...[
                  Card(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Svar på berørte aktiviteter vil bli nullstilt',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit button
                FilledButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lagre endringer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
