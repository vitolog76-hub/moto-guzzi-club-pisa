import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../models/event.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titoloController = TextEditingController();
  final _luogoController = TextEditingController();
  final _descrizioneController = TextEditingController();
  
  String _selectedTipo = 'raduno';
  
  bool _isMultiDay = false;
  DateTime _dataInizio = DateTime.now();
  DateTime _dataFine = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _oraInizio = TimeOfDay.now();
  TimeOfDay _oraFine = TimeOfDay.now();
  
  final List<String> _tipiEventi = ['raduno', 'riunione', 'cena', 'motogiro'];
  final EventService _eventService = EventService();
  
  static const Color guzziRed = Color(0xFF8B0000);

  Future<void> _selectDate(BuildContext context, bool isInizio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInizio ? _dataInizio : _dataFine,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isInizio) {
          _dataInizio = picked;
          if (_dataFine.isBefore(_dataInizio)) {
            _dataFine = _dataInizio;
          }
        } else {
          _dataFine = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isInizio) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isInizio ? _oraInizio : _oraFine,
    );
    if (picked != null) {
      setState(() {
        if (isInizio) {
          _oraInizio = picked;
        } else {
          _oraFine = picked;
        }
      });
    }
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final DateTime dataInizioCompleta = DateTime(
        _dataInizio.year,
        _dataInizio.month,
        _dataInizio.day,
        _oraInizio.hour,
        _oraInizio.minute,
      );
      
      DateTime? dataFineCompleta;
      if (_isMultiDay) {
        dataFineCompleta = DateTime(
          _dataFine.year,
          _dataFine.month,
          _dataFine.day,
          _oraFine.hour,
          _oraFine.minute,
        );
      }

      final newEvent = ClubEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: _selectedTipo,
        titolo: _titoloController.text,
        dataInizio: dataInizioCompleta,
        dataFine: dataFineCompleta,
        luogo: _luogoController.text,
        descrizione: _descrizioneController.text,
        dataCreazione: DateTime.now(),
        ruoli: {},
      );

      await _eventService.createEvent(newEvent);
      
      // Notifica per il nuovo evento
      NotificationService.showNewEventNotification(
        newEvent.titolo,
        newEvent.formattedDateRange,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento creato con successo!'),
            backgroundColor: guzziRed,
          ),
        );
        Navigator.pop(context);
      }
      
    }
  }

  void _openGoogleMaps(String indirizzo) async {
    final encodedAddress = Uri.encodeComponent(indirizzo);
    final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire Google Maps'),
          backgroundColor: guzziRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Evento'),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tipo evento', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                items: _tipiEventi.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipo = newValue!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titoloController,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Text('Evento su più giorni'),
                  const Spacer(),
                  Switch(
                    value: _isMultiDay,
                    onChanged: (value) {
                      setState(() {
                        _isMultiDay = value;
                      });
                    },
                    activeColor: guzziRed,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Data e ora INIZIO', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data inizio',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_dataInizio.day}/${_dataInizio.month}/${_dataInizio.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ora inizio',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_oraInizio.hour.toString().padLeft(2, '0')}:${_oraInizio.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_isMultiDay) ...[
                const SizedBox(height: 16),
                const Text('Data e ora FINE', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data fine',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_dataFine.day}/${_dataFine.month}/${_dataFine.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ora fine',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_oraFine.hour.toString().padLeft(2, '0')}:${_oraFine.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _luogoController,
                decoration: InputDecoration(
                  labelText: 'Luogo / Indirizzo',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: guzziRed),
                    onPressed: () {
                      final indirizzo = _luogoController.text.trim();
                      if (indirizzo.isNotEmpty) {
                        _openGoogleMaps(indirizzo);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Inserisci prima un indirizzo'),
                            backgroundColor: guzziRed,
                          ),
                        );
                      }
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un luogo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Clicca sulla mappa per verificare l\'indirizzo su Google Maps',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descrizioneController,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: guzziRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('CREA EVENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}