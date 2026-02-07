import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';

/// Bottom sheet for setting a user's handicap
class HandicapSheet extends ConsumerStatefulWidget {
  final String miniActivityId;
  final MiniActivityHandicap? existingHandicap;
  final List<HandicapUser> availableUsers;

  const HandicapSheet({
    super.key,
    required this.miniActivityId,
    this.existingHandicap,
    required this.availableUsers,
  });

  static Future<MiniActivityHandicap?> show(
    BuildContext context, {
    required String miniActivityId,
    MiniActivityHandicap? existingHandicap,
    required List<HandicapUser> availableUsers,
  }) {
    return showModalBottomSheet<MiniActivityHandicap>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => HandicapSheet(
        miniActivityId: miniActivityId,
        existingHandicap: existingHandicap,
        availableUsers: availableUsers,
      ),
    );
  }

  @override
  ConsumerState<HandicapSheet> createState() => _HandicapSheetState();
}

class _HandicapSheetState extends ConsumerState<HandicapSheet> {
  String? _selectedUserId;
  double _handicapValue = 0.0;
  bool _isLoading = false;

  final _handicapController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.existingHandicap;
    if (existing != null) {
      _selectedUserId = existing.userId;
      _handicapValue = existing.handicapValue;
      _handicapController.text = existing.handicapValue.toString();
    }
  }

  @override
  void dispose() {
    _handicapController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existingHandicap != null;

  bool get _canSave => _selectedUserId != null;

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(handicapProvider.notifier);
      final result = await notifier.setHandicap(
        miniActivityId: widget.miniActivityId,
        userId: _selectedUserId!,
        handicapValue: _handicapValue,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke lagre handicap. Prøv igjen.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.existingHandicap == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern handicap?'),
        content: const Text('Er du sikker på at du vil fjerne handicapet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(handicapProvider.notifier);
      await notifier.removeHandicap(
        miniActivityId: widget.miniActivityId,
        userId: widget.existingHandicap!.userId,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke fjerne handicap. Prøv igjen.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Rediger handicap' : 'Sett handicap',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_isEditing)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: _isLoading ? null : _delete,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // User selection
                  if (!_isEditing) ...[
                    Text(
                      'Velg spiller',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (widget.availableUsers.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ingen spillere tilgjengelig',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...widget.availableUsers.map((user) {
                        final isSelected = _selectedUserId == user.id;
                        return Card(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? Text(
                                      user.name.substring(0, 1).toUpperCase(),
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.name,
                              style: isSelected
                                  ? TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _selectedUserId = user.id);
                            },
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Show selected user when editing
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(widget.existingHandicap?.userName ?? 'Ukjent'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Handicap value
                  Text(
                    'Handicap-verdi',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Positiv verdi = bonus, negativ verdi = straff',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slider
                  Row(
                    children: [
                      Text(
                        '-10',
                        style: theme.textTheme.bodySmall,
                      ),
                      Expanded(
                        child: Slider(
                          value: _handicapValue,
                          min: -10,
                          max: 10,
                          divisions: 40,
                          label: _handicapValue.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _handicapValue = value;
                              _handicapController.text = value.toStringAsFixed(1);
                            });
                          },
                        ),
                      ),
                      Text(
                        '+10',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),

                  // Current value display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _handicapValue >= 0
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _handicapValue >= 0
                            ? '+${_handicapValue.toStringAsFixed(1)}'
                            : _handicapValue.toStringAsFixed(1),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _handicapValue >= 0
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick select buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [-5.0, -2.0, -1.0, 0.0, 1.0, 2.0, 5.0].map((n) {
                      return ActionChip(
                        label: Text(n >= 0 ? '+${n.toStringAsFixed(0)}' : n.toStringAsFixed(0)),
                        onPressed: () {
                          setState(() {
                            _handicapValue = n;
                            _handicapController.text = n.toStringAsFixed(1);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: _canSave && !_isLoading ? _save : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Lagre endringer' : 'Sett handicap'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Model for user available for handicap assignment
class HandicapUser {
  final String id;
  final String name;
  final String? profileImageUrl;

  const HandicapUser({
    required this.id,
    required this.name,
    this.profileImageUrl,
  });
}
