import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../models/event.dart';
import 'login_screen.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _eventService = EventService();
  late StreamSubscription<List<ClubEvent>> _eventsSubscription;
  List<ClubEvent> _previousEvents = [];

  static const Color guzziRed = Color(0xFF8B0000);
  static const Color guzziGold = Color(0xFFD4AF37);
  static const Color guzziDark = Color(0xFF1A1A1A);
  static const Color guzziLight = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _listenToNewEvents();
  }

  void _listenToNewEvents() {
    _eventsSubscription = _eventService.streamAllEvents().listen((events) {
      if (_previousEvents.isNotEmpty && events.length > _previousEvents.length) {
        final newEvent = events.firstWhere(
          (event) => !_previousEvents.any((e) => e.id == event.id),
          orElse: () => events.first,
        );
        
        if (newEvent.id != _previousEvents.first.id) {
          NotificationService.showNewEventNotification(
            newEvent.titolo,
            newEvent.formattedDateRange,
          );
        }
      }
      _previousEvents = events;
    });
  }

  @override
  void dispose() {
    _eventsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: guzziLight,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'MOTO GUZZI CLUB PISA',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'AQUILE ALFEE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Image.asset(
              'assets/images/logo.png',
              height: 90,
              errorBuilder: (c, e, s) => const SizedBox.shrink(),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 200,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildUserHeader(authService),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(Icons.event_note, color: guzziRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PROSSIMI EVENTI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<ClubEvent>>(
            stream: _eventService.streamUpcomingEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: guzziRed)),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Errore nel caricamento: ${snapshot.error}')),
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Nessun evento in programma',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(events[index]),
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: authService.isAdmin()
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateEventScreen()),
              ),
              backgroundColor: guzziRed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'EVENTO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildUserHeader(AuthService authService) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(authService.user?.uid)
          .get(),
      builder: (context, snapshot) {
        String nome = "Socio";
        String modelloMoto = "Passione Guzzi";
        String ruolo = "user";

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          nome = userData['nome'] ?? authService.getDisplayName();
          modelloMoto = userData['modelloMoto'] ?? 'Non specificato';
          ruolo = userData['ruolo'] ?? 'user';
        }

        return Container(
          decoration: const BoxDecoration(
            color: guzziRed,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Ciao, $nome',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                modelloMoto,
                style: const TextStyle(
                  color: guzziGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (ruolo == 'admin') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: guzziGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: guzziDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventCard(ClubEvent event) {
    // Colore in base al tipo di evento
    Color cardColor;
    Color badgeColor;
    Color textColor;
    
    switch (event.tipo) {
      case 'raduno':
        cardColor = Colors.green.shade50;
        badgeColor = Colors.green;
        textColor = Colors.green.shade800;
        break;
      case 'riunione':
        cardColor = Colors.orange.shade50;
        badgeColor = Colors.orange;
        textColor = Colors.orange.shade800;
        break;
      case 'cena':
        cardColor = Colors.red.shade50;
        badgeColor = guzziRed;
        textColor = guzziRed;
        break;
      case 'motogiro':
        cardColor = Colors.blue.shade50;
        badgeColor = Colors.blue;
        textColor = Colors.blue.shade800;
        break;
      default:
        cardColor = Colors.grey.shade50;
        badgeColor = Colors.grey;
        textColor = Colors.grey.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Badge data colorato per tipo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${event.dataInizio.day}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      Text(
                        _getMonthName(event.dataInizio.month),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      if (event.isMultiDay)
                        Text(
                          '→',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge tipo evento
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.tipo.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.titolo.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.formattedDateRange,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.luogo,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
      'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
    ];
    return months[month - 1];
  }
}