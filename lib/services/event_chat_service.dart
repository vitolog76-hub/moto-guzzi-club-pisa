import 'package:cloud_firestore/cloud_firestore.dart';

class EventChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'event_chats';

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String eventId,
  ) {
    return _firestore
        .collection(_collection)
        .doc(eventId)
        .collection('messages');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String eventId) {
    return _messagesCollection(
      eventId,
    ).orderBy('timestamp', descending: true).snapshots();
  }

  DocumentReference<Map<String, dynamic>> _readStatusDoc(
    String eventId,
    String userId,
  ) {
    return _firestore
        .collection(_collection)
        .doc(eventId)
        .collection('reads')
        .doc(userId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLatestMessage(
    String eventId,
  ) {
    return _messagesCollection(
      eventId,
    ).orderBy('timestamp', descending: true).limit(1).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamReadStatus(
    String eventId,
    String userId,
  ) {
    return _readStatusDoc(eventId, userId).snapshots();
  }

  Future<void> markEventChatAsRead(String eventId, String userId) async {
    await _readStatusDoc(eventId, userId).set({
      'lastReadAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String userName,
    required String userModello,
    required String text,
  }) async {
    await _messagesCollection(eventId).add({
      'userId': userId,
      'userName': userName,
      'userModello': userModello,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
