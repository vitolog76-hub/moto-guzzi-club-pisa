import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'partner_activities';

  Stream<QuerySnapshot<Map<String, dynamic>>> streamActivities() {
    return _firestore
        .collection(_collection)
        .orderBy('nomeAttivita')
        .snapshots();
  }

  Future<void> createActivity({
    required String nomeAttivita,
    required String indirizzo,
    required String telefono,
    required String cellulare,
    required String email,
  }) async {
    await _firestore.collection(_collection).add({
      'nomeAttivita': nomeAttivita.trim(),
      'indirizzo': indirizzo.trim(),
      'telefono': telefono.trim(),
      'cellulare': cellulare.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateActivity({
    required String id,
    required String nomeAttivita,
    required String indirizzo,
    required String telefono,
    required String cellulare,
    required String email,
  }) async {
    await _firestore.collection(_collection).doc(id).update({
      'nomeAttivita': nomeAttivita.trim(),
      'indirizzo': indirizzo.trim(),
      'telefono': telefono.trim(),
      'cellulare': cellulare.trim(),
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteActivity(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
