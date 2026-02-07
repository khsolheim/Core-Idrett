import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final String prefKey;
  final IconData icon;

  const NotificationToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.prefKey,
    required this.icon,
  });

  @override
  State<NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<NotificationToggle> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(widget.prefKey) ?? true;
    });
  }

  Future<void> _savePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefKey, value);
    setState(() {
      _enabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon),
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: _enabled,
      onChanged: _savePreference,
    );
  }
}
