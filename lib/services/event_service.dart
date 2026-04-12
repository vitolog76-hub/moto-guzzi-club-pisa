import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _eventsCollection = 'events';

  Future<void> createEvent(ClubEvent event) async {
    await _firestore.collection(_eventsCollection).doc(event.id).set(event.toMap());
  }

  Stream<List<ClubEvent>> streamEvents() {
    return _firestore
        .collection(_eventsCollection)
        .snapshots()
        .map((snapshot) {
          final tutti = snapshot.docs
              .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
              .toList();
          
          // Ordina per dataInizio (più recente prima)
          tutti.sort((a, b) => a.dataInizio.compareTo(b.dataInizio));
          return tutti;
        });
  }

  Stream<List<ClubEvent>> streamAllEvents() {
    return _firestore
        .collection(_eventsCollection)
        .snapshots()
        .map((snapshot) {
          final tutti = snapshot.docs
              .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
              .toList();
          
          tutti.sort((a, b) => a.dataInizio.compareTo(b.dataInizio));
          return tutti;
        });
  }

  Stream<List<ClubEvent>> streamUpcomingEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection(_eventsCollection)
        .snapshots()
        .map((snapshot) {
          final tutti = snapshot.docs
              .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
              .toList();
          
          // Filtra eventi futuri (dataInizio >= oggi)
          final futuri = tutti.where((event) {
            return event.dataInizio.isAfter(today.subtract(const Duration(days: 1)));
          }).toList();
          
          // ORDINA PER DATA (dal più vicino al più lontano)
          futuri.sort((a, b) => a.dataInizio.compareTo(b.dataInizio));
          
          print('Eventi futuri ordinati:'); // Debug
          for (var e in futuri) {
            print('  ${e.titolo} - ${e.dataInizio.day}/${e.dataInizio.month}/${e.dataInizio.year}');
          }
          
          return futuri;
        });
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(_eventsCollection).doc(eventId).delete();
  }

  Future<void> updateEvent(ClubEvent event) async {
    await _firestore.collection(_eventsCollection).doc(event.id).update(event.toMap());
  }
  
  Future<ClubEvent?> getEvent(String eventId) async {
    final doc = await _firestore.collection(_eventsCollection).doc(eventId).get();
    if (doc.exists) {
      return ClubEvent.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}