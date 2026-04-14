import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  ClubEvent? _selectedEvent;
  bool _customEdited = false;
  static const Color guzziRed = Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Promemoria evento';
    _bodyController.text = '<titolo evento> inizia tra 3 giorni.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String get _defaultBody {
    final titolo = _selectedEvent?.titolo ?? '<titolo evento>';
    return '$titolo inizia tra 3 giorni.';
  }

  void _applyDefaultTemplate() {
    _titleController.text = 'Promemoria evento';
    _bodyController.text = _defaultBody;
    _customEdited = false;
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiato negli appunti'),
        backgroundColor: guzziRed,
      ),
    );
  }

  Future<void> _openFirebaseConsole() async {
    final uri = Uri.parse(
      'https://console.firebase.google.com/project/motoguzziclub-97318/notification/compose',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invia Notifica',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ClubEvent>>(
        stream: _eventService.streamUpcomingEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: guzziRed),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore: ${snapshot.error}'),
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'Nessun evento disponibile',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          _selectedEvent ??= events.first;
          if (!_customEdited &&
              _bodyController.text.contains('<titolo evento>')) {
            _applyDefaultTemplate();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Seleziona evento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEvent?.id,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: events
                    .map(
                      (event) => DropdownMenuItem<String>(
                        value: event.id,
                        child: Text(event.titolo),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedEvent = events.firstWhere((e) => e.id == id);
                    if (!_customEdited) {
                      _applyDefaultTemplate();
                    }
                  });
                },
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo notifica',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _customEdited = true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _copyToClipboard(_titleController.text.trim(), 'Titolo'),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copia titolo'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Testo notifica',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _customEdited = true,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(_applyDefaultTemplate);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Ripristina template'),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _copyToClipboard(_bodyController.text.trim(), 'Testo'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copia testo'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openFirebaseConsole,
                icon: const Icon(Icons.open_in_new),
                label: const Text(
                  'Apri Firebase Console',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: guzziRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Suggerimento: in Firebase Notifications incolla titolo e testo, poi pianifica invio 3 giorni prima.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
