import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _eventsCollection = 'events';

  Future<void> createEvent(ClubEvent event) async {
    await _firestore
        .collection(_eventsCollection)
        .doc(event.id)
        .set(event.toMap());
  }

  Stream<List<ClubEvent>> streamEvents() {
    return _firestore.collection(_eventsCollection).snapshots().map((snapshot) {
      final tutti = snapshot.docs
          .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
          .toList();

      // Ordina per dataInizio (più recente prima)
      tutti.sort((a, b) => a.dataInizio.compareTo(b.dataInizio));
      return tutti;
    });
  }

  Stream<List<ClubEvent>> streamAllEvents() {
    return _firestore.collection(_eventsCollection).snapshots().map((snapshot) {
      final tutti = snapshot.docs
          .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
          .toList();

      tutti.sort((a, b) => a.dataInizio.compareTo(b.dataInizio));
      return tutti;
    });
  }

  Stream<List<ClubEvent>> streamUpcomingEvents() {
    return _firestore.collection(_eventsCollection).snapshots().map((snapshot) {
      final tutti = snapshot.docs
          .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
          .toList();

      // Mostra gli eventi non ancora conclusi.
      final futuri = tutti.where((event) {
        return !event.isPastEvent;
      }).toList();

      futuri.sort((a, b) => a.dataInizio.compareTo(b.dataInizio));
      return futuri;
    });
  }

  Stream<List<ClubEvent>> streamArchivedEvents() {
    return _firestore.collection(_eventsCollection).snapshots().map((snapshot) {
      final tutti = snapshot.docs
          .map((doc) => ClubEvent.fromMap(doc.id, doc.data()))
          .toList();

      final archiviati = tutti.where((event) => event.isPastEvent).toList();

      // Archivio dal più recente al più vecchio.
      archiviati.sort(
        (a, b) => b.dataRiferimentoFine.compareTo(a.dataRiferimentoFine),
      );
      return archiviati;
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection(_eventsCollection).doc(eventId).delete();
  }

  Future<void> updateEvent(ClubEvent event) async {
    await _firestore
        .collection(_eventsCollection)
        .doc(event.id)
        .update(event.toMap());
  }

  Future<ClubEvent?> getEvent(String eventId) async {
    final doc = await _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .get();
    if (doc.exists) {
      return ClubEvent.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}
