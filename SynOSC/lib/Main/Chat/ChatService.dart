import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Mensagem.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _gerarConversaId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  /// Retorna um stream de mensagens da conversa entre dois usuários
  Stream<List<Mensagem>> getMensagens(String userId1, String userId2) {
    final conversaId = _gerarConversaId(userId1, userId2);

    return _db
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Mensagem.fromDoc(doc)).toList());
  }

  /// Envia uma nova mensagem e atualiza o documento da conversa
  Future<void> enviarMensagem({
    required String deId,
    required String paraId,
    required String texto,
  }) async {
    final conversaId = _gerarConversaId(deId, paraId);
    final timestamp = Timestamp.now();

    final mensagem = {
      'remetenteId': deId,
      'texto': texto,
      'timestamp': timestamp,
    };

    final conversaRef = _db.collection('conversas').doc(conversaId);
    final mensagensRef = conversaRef.collection('mensagens');

    // Garante que o documento da conversa existe
    await conversaRef.set({
      'participantes': [deId, paraId],
      'ultimaMensagem': texto,
      'remetenteId': deId,
      'timestamp': timestamp,
    }, SetOptions(merge: true));

    // Adiciona a mensagem
    await mensagensRef.add(mensagem);
  }
}
