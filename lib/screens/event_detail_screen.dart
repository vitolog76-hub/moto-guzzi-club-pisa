import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/participation.dart';
import '../services/event_service.dart';
import '../services/participation_service.dart';
import 'home_screen.dart';
import 'edit_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final ClubEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ParticipationService _participationService = ParticipationService();
  final EventService _eventService = EventService();
  String _currentUserStatus = 'indeciso';
  String? _currentUserId;
  String _currentUserRuolo = 'user';
  
  static const Color guzziRed = Color(0xFF8B0000);
  static const Color guzziGold = Color(0xFFD4AF37);
  static const Color guzziDark = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCurrentUserRuolo();
    if (_currentUserId != null) {
      _loadUserStatus();
    }
  }

  Future<void> _loadCurrentUserRuolo() async {
    if (_currentUserId == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
    if (doc.exists) {
      setState(() {
        _currentUserRuolo = doc.data()?['ruolo'] ?? 'user';
      });
    }
  }

  Future<void> _loadUserStatus() async {
    final status = await _participationService.getUserParticipationStatus(
      _currentUserId!,
      widget.event.id,
    );
    setState(() {
      _currentUserStatus = status;
    });
  }

  Future<void> _updateStatus(String nuovoStato) async {
    if (_currentUserId == null) return;
    
    await _participationService.setParticipation(
      _currentUserId!,
      widget.event.id,
      nuovoStato,
    );
    
    setState(() {
      _currentUserStatus = nuovoStato;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hai risposto: $nuovoStato'),
        backgroundColor: guzziRed,
      ),
    );
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina evento'),
        content: Text('Sei sicuro di voler eliminare "${widget.event.titolo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _eventService.deleteEvent(widget.event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento eliminato con successo'),
            backgroundColor: guzziRed,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  void _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventScreen(event: widget.event),
      ),
    );
    
    if (result == true && mounted) {
      // Ricarica la pagina per mostrare i dati aggiornati
      setState(() {});
    }
  }

  void _openGoogleMaps() async {
    final indirizzo = widget.event.luogo;
    if (indirizzo.isEmpty) return;
    
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
        title: Text(
          widget.event.titolo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
        actions: [
          if (_currentUserRuolo == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Modifica evento',
              onPressed: _editEvent,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Elimina evento',
              onPressed: _deleteEvent,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dettagli evento
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.titolo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: guzziRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.event.tipo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: guzziRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _infoRow('Data', widget.event.formattedDateTime),
                    const SizedBox(height: 12),
                    
                    // Luogo con Google Maps cliccabile
                    GestureDetector(
                      onTap: _openGoogleMaps,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 80),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.event.luogo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: guzziRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map, size: 14, color: guzziRed),
                                      SizedBox(width: 4),
                                      Text(
                                        'MAPPA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: guzziRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    _infoRow('Descrizione', widget.event.descrizione),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Sezione partecipazione
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LA TUA PARTECIPAZIONE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatusButton('si', 'CONFERMO', Colors.green),
                        _buildStatusButton('no', 'NON POSSO', Colors.red),
                        _buildStatusButton('indeciso', 'INDECISO', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lista partecipanti
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PARTECIPANTI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Participation>>(
                      stream: _participationService.streamParticipationsForEvent(widget.event.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError) {
                          return Center(child: Text('Errore: ${snapshot.error}'));
                        }
                        
                        final partecipazioni = snapshot.data ?? [];
                        
                        final partecipantiSi = <String>[];
                        final partecipantiNo = <String>[];
                        final partecipantiIndeciso = <String>[];
                        
                        for (var p in partecipazioni) {
                          if (p.stato == 'si') partecipantiSi.add(p.userId);
                          else if (p.stato == 'no') partecipantiNo.add(p.userId);
                          else if (p.stato == 'indeciso') partecipantiIndeciso.add(p.userId);
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (partecipantiSi.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CONFERMATI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...partecipantiSi.map((userId) => FutureBuilder(
                                      future: _getUserName(userId),
                                      builder: (context, snapshot) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4, left: 8),
                                          child: Text(snapshot.data ?? 'Caricamento...'),
                                        );
                                      },
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (partecipantiNo.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NON POSSONO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...partecipantiNo.map((userId) => FutureBuilder(
                                      future: _getUserName(userId),
                                      builder: (context, snapshot) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4, left: 8),
                                          child: Text(snapshot.data ?? 'Caricamento...'),
                                        );
                                      },
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (partecipantiIndeciso.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'INDECISI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...partecipantiIndeciso.map((userId) => FutureBuilder(
                                      future: _getUserName(userId),
                                      builder: (context, snapshot) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4, left: 8),
                                          child: Text(snapshot.data ?? 'Caricamento...'),
                                        );
                                      },
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (partecipazioni.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Nessuna risposta ancora',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(String value, String label, Color color) {
    final isSelected = _currentUserStatus == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _updateStatus(value),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final nome = data['nome'] ?? 'Sconosciuto';
        final modello = data['modelloMoto'] ?? '';
        if (modello.isNotEmpty) {
          return '$nome ($modello)';
        }
        return nome;
      }
      return 'Utente sconosciuto';
    } catch (e) {
      return 'Utente sconosciuto';
    }
  }
}