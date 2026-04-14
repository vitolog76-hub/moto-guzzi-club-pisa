import 'package:cloud_firestore/cloud_firestore.dart';

class ClubEvent {
  final String id;
  final String tipo;
  final String titolo;
  final DateTime dataInizio;
  final DateTime? dataFine;
  final String luogo;
  final String? puntoRitrovo;
  final String descrizione;
  final DateTime dataCreazione;
  final Map<String, List<String>> ruoli;
  final List<String> imageUrls;

  ClubEvent({
    required this.id,
    required this.tipo,
    required this.titolo,
    required this.dataInizio,
    this.dataFine,
    required this.luogo,
    this.puntoRitrovo,
    required this.descrizione,
    required this.dataCreazione,
    required this.ruoli,
    this.imageUrls = const [],
  });

  bool get isMultiDay => dataFine != null;

  bool get hasPuntoRitrovo => puntoRitrovo != null && puntoRitrovo!.isNotEmpty;

  bool get hasImages => imageUrls.isNotEmpty;

  String? get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  DateTime get dataRiferimentoFine => dataFine ?? dataInizio;

  bool get isPastEvent => dataRiferimentoFine.isBefore(DateTime.now());

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
      return _formatDateTime(dataInizio);
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
      'puntoRitrovo': puntoRitrovo,
      'descrizione': descrizione,
      'dataCreazione': Timestamp.fromDate(dataCreazione),
      'ruoli': ruoli,
      'imageUrls': imageUrls,
    };
  }

  factory ClubEvent.fromMap(String id, Map<String, dynamic> map) {
    DateTime dataInizioDateTime;
    DateTime? dataFineDateTime;

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
      final oldDataField = map['data'];
      if (oldDataField is Timestamp) {
        dataInizioDateTime = oldDataField.toDate();
      } else if (oldDataField is DateTime) {
        dataInizioDateTime = oldDataField;
      } else {
        dataInizioDateTime = DateTime.now();
      }
    }

    final dataFineField = map['dataFine'];
    if (dataFineField != null) {
      if (dataFineField is Timestamp) {
        dataFineDateTime = dataFineField.toDate();
      } else if (dataFineField is DateTime) {
        dataFineDateTime = dataFineField;
      }
    }

    // Backward compatible: support both imageUrls (list) and legacy imageUrl (string)
    List<String> parsedImageUrls;
    final imageUrlsList = map['imageUrls'];
    if (imageUrlsList is List) {
      parsedImageUrls = imageUrlsList.cast<String>();
    } else {
      final legacyUrl = map['imageUrl'];
      if (legacyUrl is String && legacyUrl.isNotEmpty) {
        parsedImageUrls = [legacyUrl];
      } else {
        parsedImageUrls = [];
      }
    }

    return ClubEvent(
      id: id,
      tipo: map['tipo'] ?? '',
      titolo: map['titolo'] ?? '',
      dataInizio: dataInizioDateTime,
      dataFine: dataFineDateTime,
      luogo: map['luogo'] ?? '',
      puntoRitrovo: map['puntoRitrovo'],
      descrizione: map['descrizione'] ?? '',
      dataCreazione: (map['dataCreazione'] as Timestamp).toDate(),
      ruoli: Map<String, List<String>>.from(map['ruoli'] ?? {}),
      imageUrls: parsedImageUrls,
    );
  }
}
