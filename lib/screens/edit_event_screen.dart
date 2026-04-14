import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/image_storage_service.dart';
import '../widgets/image_picker_section.dart';

class EditEventScreen extends StatefulWidget {
  final ClubEvent event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titoloController;
  late TextEditingController _luogoController;
  late TextEditingController _puntoRitrovoController;
  late TextEditingController _descrizioneController;
  
  late String _selectedTipo;
  late bool _isMultiDay;
  late DateTime _dataInizio;
  late DateTime _dataFine;
  late TimeOfDay _oraInizio;
  late TimeOfDay _oraFine;
  
  final List<String> _tipiEventi = ['raduno', 'riunione', 'cena', 'motogiro'];
  final EventService _eventService = EventService();
  final ImageStorageService _imageService = ImageStorageService();

  late List<String> _existingImageUrls;
  List<XFile> _newImages = [];
  final List<String> _removedImageUrls = [];
  bool _isSaving = false;
  
  static const Color guzziRed = Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    
    _titoloController = TextEditingController(text: widget.event.titolo);
    _luogoController = TextEditingController(text: widget.event.luogo);
    _puntoRitrovoController = TextEditingController(text: widget.event.puntoRitrovo ?? '');
    _descrizioneController = TextEditingController(text: widget.event.descrizione);
    
    _selectedTipo = widget.event.tipo;
    _isMultiDay = widget.event.isMultiDay;
    _dataInizio = widget.event.dataInizio;
    _dataFine = widget.event.dataFine ?? widget.event.dataInizio;
    _oraInizio = TimeOfDay.fromDateTime(widget.event.dataInizio);
    _oraFine = widget.event.dataFine != null 
        ? TimeOfDay.fromDateTime(widget.event.dataFine!) 
        : TimeOfDay.fromDateTime(widget.event.dataInizio);
    _existingImageUrls = List.from(widget.event.imageUrls);
  }

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

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

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

      // Delete removed images from storage
      if (_removedImageUrls.isNotEmpty) {
        await _imageService.deleteImages(_removedImageUrls);
      }

      // Upload new images
      List<String> newUploadedUrls = [];
      if (_newImages.isNotEmpty) {
        try {
          newUploadedUrls = await _imageService.uploadEventImages(
            widget.event.id,
            _newImages,
          );
        } catch (e) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore upload immagini: $e'),
                backgroundColor: guzziRed,
              ),
            );
          }
          return;
        }
      }

      final allImageUrls = [..._existingImageUrls, ...newUploadedUrls];

      final updatedEvent = ClubEvent(
        id: widget.event.id,
        tipo: _selectedTipo,
        titolo: _titoloController.text,
        dataInizio: dataInizioCompleta,
        dataFine: dataFineCompleta,
        luogo: _luogoController.text,
        puntoRitrovo: _puntoRitrovoController.text.trim().isEmpty ? null : _puntoRitrovoController.text.trim(),
        descrizione: _descrizioneController.text,
        dataCreazione: widget.event.dataCreazione,
        ruoli: widget.event.ruoli,
        imageUrls: allImageUrls,
      );

      await _eventService.updateEvent(updatedEvent);
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento aggiornato con successo!'),
            backgroundColor: guzziRed,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Evento'),
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
                initialValue: _selectedTipo,
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
                    activeThumbColor: guzziRed,
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
                decoration: const InputDecoration(
                  labelText: 'Luogo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un luogo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _puntoRitrovoController,
                decoration: const InputDecoration(
                  labelText: 'Punto di ritrovo (opzionale)',
                  hintText: 'Es: Parcheggio dello stadio, ore 09:00',
                  border: OutlineInputBorder(),
                ),
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
              ImagePickerSection(
                existingImageUrls: _existingImageUrls,
                newImages: _newImages,
                onNewImagesPicked: (files) {
                  setState(() {
                    _newImages = [..._newImages, ...files];
                  });
                },
                onExistingImageRemoved: (index) {
                  setState(() {
                    _removedImageUrls.add(_existingImageUrls[index]);
                    _existingImageUrls = List.from(_existingImageUrls)..removeAt(index);
                  });
                },
                onNewImageRemoved: (index) {
                  setState(() {
                    _newImages = List.from(_newImages)..removeAt(index);
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: guzziRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('AGGIORNA EVENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
