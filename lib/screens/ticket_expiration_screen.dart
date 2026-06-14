import 'package:flutter/material.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../utils/albanian_date.dart';
import '../utils/messages.dart';
import '../utils/navigation.dart';
import '../widgets/app_button.dart';
import '../widgets/brand_mark.dart';
import '../widgets/screen_shell.dart';

class TicketExpirationScreen extends StatefulWidget {
  const TicketExpirationScreen({required this.user, super.key});

  final AppSessionUser user;

  @override
  State<TicketExpirationScreen> createState() => _TicketExpirationScreenState();
}

class _TicketExpirationScreenState extends State<TicketExpirationScreen> {
  final _databaseService = DatabaseService();
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserData>(
      initialData: AppUserData.demo(
        uid: widget.user.uid,
        email: widget.user.email,
        username: widget.user.displayName,
      ),
      stream: _databaseService.watchUser(widget.user),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            AppUserData.demo(
              uid: widget.user.uid,
              email: widget.user.email,
              username: widget.user.displayName,
            );
        final current = _selectedDate ?? _parseDate(data.expiresAt);

        return ScreenShell(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHeader(
                    title: 'Vlefshmëria e biletës',
                    subtitle: 'Zgjidh datën kur skadon bileta demo',
                    showBack: true,
                  ),
                  const SizedBox(height: 30),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 34),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              formatAlbanianDate(current),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Zgjidh datën',
                    icon: Icons.calendar_month_rounded,
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Ruaj datën',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: () => _save(current),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Kthehu',
                    style: AppButtonStyle.secondary,
                    onPressed: () => maybePopRoute(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _selectedDate ?? oneMonthFrom(now);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save(DateTime date) async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _databaseService.saveTicketExpiration(widget.user, date);
      if (mounted) {
        showAppMessage(context, 'Data e biletës u përditësua.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? oneMonthFrom(DateTime.now());
  }
}
