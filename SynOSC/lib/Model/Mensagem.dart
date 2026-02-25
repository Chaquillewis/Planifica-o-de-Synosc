import 'package:cloud_firestore/cloud_firestore.dart';

class Mensagem {
  final String id;
  final String remetenteId;
  final String texto;
  final Timestamp timestamp;

  Mensagem({
    required this.id,
    required this.remetenteId,
    required this.texto,
    required this.timestamp,
  });

  factory Mensagem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Mensagem(
      id: doc.id,
      remetenteId: data['remetenteId'] ?? '',
      texto: data['texto'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'remetenteId': remetenteId,
      'texto': texto,
      'timestamp': timestamp,
    };
  }
}
