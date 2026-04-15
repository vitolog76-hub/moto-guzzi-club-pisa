import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/event_chat_service.dart';
import '../services/event_service.dart';
import '../services/participation_service.dart';
import '../models/event.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import 'members_list_screen.dart';
import 'partner_activities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _eventService = EventService();
  final ParticipationService _participationService = ParticipationService();
  final EventChatService _chatService = EventChatService();

  static const Color guzziRed = Color(0xFF8B0000);
  static const Color guzziGold = Color(0xFFD4AF37);
  static const Color guzziDark = Color(0xFF1A1A1A);
  static const Color guzziLight = Color(0xFFF8F9FA);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? 12.0 : 16.0;
    final logoSize = isLandscape ? 80.0 : 95.0;
    final titleFontSize = isLandscape ? 18.0 : 22.0;
    final subtitleFontSize = isLandscape ? 14.0 : 18.0;
    final toolbarHeight = isLandscape ? 84.0 : 96.0;

    return Scaffold(
      backgroundColor: guzziLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: horizontalPadding),
              child: Image.asset(
                'assets/images/logo.png',
                height: logoSize,
                width: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moto Guzzi Club Pisa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    'Aquile Alfee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: toolbarHeight,
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
          SliverToBoxAdapter(child: _buildUserHeader(authService)),
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
                  child: Center(
                    child: CircularProgressIndicator(color: guzziRed),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Errore nel caricamento: ${snapshot.error}'),
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(events[index]),
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, color: guzziRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'EVENTI ARCHIVIATI',
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
            stream: _eventService.streamArchivedEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: guzziRed),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text('Errore archivio: ${snapshot.error}'),
                  ),
                );
              }

              final archivedEvents = snapshot.data ?? [];
              if (archivedEvents.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Text(
                      'Nessun evento archiviato',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.grey.shade100,
                    collapsedBackgroundColor: Colors.grey.shade100,
                    title: Text(
                      'Mostra archivio (${archivedEvents.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: archivedEvents
                        .map(
                          (event) => _buildEventCard(event, isArchived: true),
                        )
                        .toList(),
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
                MaterialPageRoute(
                  builder: (context) => const CreateEventScreen(),
                ),
              ),
              backgroundColor: guzziRed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'EVENTO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
        String? grado;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          nome = userData['nome'] ?? authService.getDisplayName();
          modelloMoto = userData['modelloMoto'] ?? 'Non specificato';
          ruolo = userData['ruolo'] ?? 'user';
          final gradoRaw = userData['grado'];
          if (gradoRaw != null) {
            final g = gradoRaw.toString().trim();
            if (g.isNotEmpty) {
              grado = g;
            }
          }
        }

        final saluto = grado != null ? 'Ciao, $nome ($grado)' : 'Ciao, $nome';

        return Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 239, 233, 233),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                saluto,
                style: const TextStyle(
                  color: Color.fromARGB(255, 66, 66, 66),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                modelloMoto,
                style: const TextStyle(
                  color: Color.fromARGB(255, 143, 12, 12),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickAccessButton(
                icon: Icons.groups_2_rounded,
                title: 'Elenco Soci',
                subtitle: 'Visualizza tutti i membri registrati',
                colors: const [
                  Color.fromARGB(255, 5, 137, 69),
                  Color.fromARGB(255, 0, 102, 51),
                ],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const MembersListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildQuickAccessButton(
                icon: Icons.storefront_rounded,
                title: 'Negozi Convenzionati',
                subtitle: 'Scopri attività e contatti utili',
                colors: const [Color(0xFF8B0000), Color(0xFFB22222)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const PartnerActivitiesScreen(),
                    ),
                  );
                },
              ),
              if (ruolo == 'admin') ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
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

  Widget _buildEventCard(ClubEvent event, {bool isArchived = false}) {
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
        color: isArchived ? Colors.grey.shade100 : cardColor,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.titolo.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildUnreadChatIndicator(event.id),
                          const SizedBox(width: 8),
                          _buildConfirmedBadge(event.id),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.formattedDateRange,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.luogo,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (event.thumbnailUrl != null) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 60, maxHeight: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event.thumbnailUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: guzziRed),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                Icon(
                  Icons.chevron_right,
                  color: isArchived
                      ? Colors.grey.shade300
                      : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'GEN',
      'FEB',
      'MAR',
      'APR',
      'MAG',
      'GIU',
      'LUG',
      'AGO',
      'SET',
      'OTT',
      'NOV',
      'DIC',
    ];
    return months[month - 1];
  }

  Widget _buildConfirmedBadge(String eventId) {
    return StreamBuilder(
      stream: _participationService.streamParticipationsForEvent(eventId),
      builder: (context, snapshot) {
        final partecipazioni = snapshot.data ?? [];
        final confirmedCount = partecipazioni
            .where((p) => p.stato == 'si')
            .length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'CONFERMATI $confirmedCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadChatIndicator(String eventId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatService.streamLatestMessage(eventId),
      builder: (context, latestSnapshot) {
        final latestDocs = latestSnapshot.data?.docs ?? [];
        if (latestDocs.isEmpty) return const SizedBox.shrink();

        final latestData = latestDocs.first.data();
        final latestTimestamp = latestData['timestamp'];
        if (latestTimestamp is! Timestamp) return const SizedBox.shrink();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _chatService.streamReadStatus(eventId, userId),
          builder: (context, readSnapshot) {
            final readData = readSnapshot.data?.data();
            final lastReadRaw = readData?['lastReadAt'];
            final lastReadAt = lastReadRaw is Timestamp
                ? lastReadRaw.toDate()
                : null;
            final hasUnread =
                lastReadAt == null ||
                latestTimestamp.toDate().isAfter(lastReadAt);

            if (!hasUnread) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: guzziRed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 14,
                color: Colors.white,
              ),
            );
          },
        );
      },
    );
  }
}
