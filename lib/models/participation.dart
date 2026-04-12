class Participation {
  final String id;
  final String userId;
  final String eventId;
  final String stato; // 'si', 'no', 'indeciso'
  final DateTime dataRisposta;

  Participation({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.stato,
    required this.dataRisposta,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'stato': stato,
      'dataRisposta': dataRisposta,
    };
  }

  factory Participation.fromMap(String id, Map<String, dynamic> map) {
    return Participation(
      id: id,
      userId: map['userId'] ?? '',
      eventId: map['eventId'] ?? '',
      stato: map['stato'] ?? 'indeciso',
      dataRisposta: (map['dataRisposta'] as dynamic).toDate(),
    );
  }
}