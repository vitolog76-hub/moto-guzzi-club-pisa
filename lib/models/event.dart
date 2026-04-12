import 'package:cloud_firestore/cloud_firestore.dart';

class ClubEvent {
  final String id;
  final String tipo;
  final String titolo;
  final DateTime dataInizio;
  final DateTime? dataFine;
  final String luogo;
  final String descrizione;
  final DateTime dataCreazione;
  final Map<String, List<String>> ruoli;

  ClubEvent({
    required this.id,
    required this.tipo,
    required this.titolo,
    required this.dataInizio,
    this.dataFine,
    required this.luogo,
    required this.descrizione,
    required this.dataCreazione,
    required this.ruoli,
  });

  bool get isMultiDay => dataFine != null;
  
  String get formattedDateRange {
    if (dataFine == null) {
      return _formatDate(dataInizio);
    }
    return '${_formatDate(dataInizio)} - ${_formatDate(dataFine!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedDateTime {
    if (dataFine == null) {
      return '${_formatDateTime(dataInizio)}';
    }
    return 'Dal ${_formatDateTime(dataInizio)} al ${_formatDateTime(dataFine!)}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ore ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'titolo': titolo,
      'dataInizio': Timestamp.fromDate(dataInizio),
      'dataFine': dataFine != null ? Timestamp.fromDate(dataFine!) : null,
      'luogo': luogo,
      'descrizione': descrizione,
      'dataCreazione': Timestamp.fromDate(dataCreazione),
      'ruoli': ruoli,
    };
  }

  factory ClubEvent.fromMap(String id, Map<String, dynamic> map) {
    // Supporto sia per vecchio campo 'data' che per nuovo 'dataInizio'
    DateTime dataInizioDateTime;
    DateTime? dataFineDateTime;
    
    // Prova a leggere dataInizio (nuovo formato)
    final dataInizioField = map['dataInizio'];
    if (dataInizioField != null) {
      if (dataInizioField is Timestamp) {
        dataInizioDateTime = dataInizioField.toDate();
      } else if (dataInizioField is DateTime) {
        dataInizioDateTime = dataInizioField;
      } else {
        dataInizioDateTime = DateTime.now();
      }
    } else {
      // Fallback al vecchio campo 'data'
      final oldDataField = map['data'];
      if (oldDataField is Timestamp) {
        dataInizioDateTime = oldDataField.toDate();
      } else if (oldDataField is DateTime) {
        dataInizioDateTime = oldDataField;
      } else {
        dataInizioDateTime = DateTime.now();
      }
    }
    
    // Leggi dataFine (solo nuovo formato)
    final dataFineField = map['dataFine'];
    if (dataFineField != null) {
      if (dataFineField is Timestamp) {
        dataFineDateTime = dataFineField.toDate();
      } else if (dataFineField is DateTime) {
        dataFineDateTime = dataFineField;
      }
    }
    
    return ClubEvent(
      id: id,
      tipo: map['tipo'] ?? '',
      titolo: map['titolo'] ?? '',
      dataInizio: dataInizioDateTime,
      dataFine: dataFineDateTime,
      luogo: map['luogo'] ?? '',
      descrizione: map['descrizione'] ?? '',
      dataCreazione: (map['dataCreazione'] as Timestamp).toDate(),
      ruoli: Map<String, List<String>>.from(map['ruoli'] ?? {}),
    );
  }
}