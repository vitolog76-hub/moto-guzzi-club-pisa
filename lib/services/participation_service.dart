import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/participation.dart';

class ParticipationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'participations';

  // Imposta la partecipazione di un utente a un evento
  Future<void> setParticipation(String userId, String eventId, String stato) async {
    final id = '${eventId}_$userId';
    await _firestore.collection(_collection).doc(id).set({
      'userId': userId,
      'eventId': eventId,
      'stato': stato,
      'dataRisposta': Timestamp.now(),
    });
  }

  // Stream delle partecipazioni per un evento
  Stream<List<Participation>> streamParticipationsForEvent(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Participation.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Ottiene lo stato di partecipazione di un utente per un evento
  Future<String> getUserParticipationStatus(String userId, String eventId) async {
    final id = '${eventId}_$userId';
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return doc.data()?['stato'] ?? 'indeciso';
    }
    return 'indeciso';
  }

  // Stream dello stato di partecipazione di un utente per un evento
  Stream<String> streamUserParticipationStatus(String userId, String eventId) {
    final id = '${eventId}_$userId';
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data()?['stato'] ?? 'indeciso';
      }
      return 'indeciso';
    });
  }
}