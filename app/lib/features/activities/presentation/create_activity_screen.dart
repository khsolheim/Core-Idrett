import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/activity.dart';
import '../providers/activity_provider.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  final String teamId;

  const CreateActivityScreen({super.key, required this.teamId});

  @override
  ConsumerState<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  ActivityType _type = ActivityType.training;
  RecurrenceType _recurrence = RecurrenceType.once;
  ResponseType _responseType = ResponseType.yesNo;
  DateTime _firstDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _recurrenceEndDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _responseDeadlineHours;

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _firstDate = picked);
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _firstDate.add(const Duration(days: 90)),
      firstDate: _firstDate,
      lastDate: _firstDate.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _recurrenceEndDate = picked);
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
      initialTime: _endTime ?? (_startTime?.replacing(hour: (_startTime!.hour + 1) % 24) ?? const TimeOfDay(hour: 20, minute: 0)),
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

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref.read(createActivityProvider.notifier).createActivity(
          teamId: widget.teamId,
          title: _titleController.text.trim(),
          type: _type,
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          recurrenceType: _recurrence,
          recurrenceEndDate: _recurrence != RecurrenceType.once ? _recurrenceEndDate : null,
          responseType: _responseType,
          responseDeadlineHours: _responseDeadlineHours,
          firstDate: _firstDate,
          startTime: _startTime != null ? _formatTimeOfDay(_startTime!) : null,
          endTime: _endTime != null ? _formatTimeOfDay(_endTime!) : null,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktivitet opprettet')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke opprette aktivitet')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d. MMMM yyyy', 'nb_NO');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ny aktivitet'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tittel',
                hintText: 'F.eks. "Trening" eller "Seriekamp"',
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

            // Type
            DropdownButtonFormField<ActivityType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
              ),
              items: ActivityType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Dato'),
              subtitle: Text(dateFormat.format(_firstDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),
            const Divider(),

            // Time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Fra'),
                    subtitle: Text(_startTime != null ? _formatTimeOfDay(_startTime!) : 'Ikke satt'),
                    onTap: _selectStartTime,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Til'),
                    subtitle: Text(_endTime != null ? _formatTimeOfDay(_endTime!) : 'Ikke satt'),
                    onTap: _selectEndTime,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Sted (valgfritt)',
                prefixIcon: Icon(Icons.location_on),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Recurrence
            DropdownButtonFormField<RecurrenceType>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Gjentagelse',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _recurrence = value);
              },
            ),
            if (_recurrence != RecurrenceType.once) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gjentas til'),
                subtitle: Text(
                  _recurrenceEndDate != null
                      ? dateFormat.format(_recurrenceEndDate!)
                      : 'Ikke satt (standard: 1 år)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectRecurrenceEndDate,
              ),
            ],
            const SizedBox(height: 16),

            // Response type
            DropdownButtonFormField<ResponseType>(
              initialValue: _responseType,
              decoration: const InputDecoration(
                labelText: 'Svartype',
                prefixIcon: Icon(Icons.how_to_vote),
              ),
              items: ResponseType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _responseType = value);
              },
            ),
            if (_responseType == ResponseType.withDeadline) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _responseDeadlineHours ?? 24,
                decoration: const InputDecoration(
                  labelText: 'Svarfrist',
                  prefixIcon: Icon(Icons.timer),
                ),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 timer før')),
                  DropdownMenuItem(value: 12, child: Text('12 timer før')),
                  DropdownMenuItem(value: 24, child: Text('24 timer før')),
                  DropdownMenuItem(value: 48, child: Text('48 timer før')),
                  DropdownMenuItem(value: 72, child: Text('72 timer før')),
                ],
                onChanged: (value) {
                  setState(() => _responseDeadlineHours = value);
                },
              ),
            ],
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse (valgfritt)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _createActivity,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Opprett aktivitet'),
            ),
          ],
        ),
      ),
    );
  }
}
