class Conversa {
  String _nome;
  String _mensagem;
  String _path_foto;
  String _userId;

  Conversa(this._nome, this._mensagem, this._path_foto, this._userId);

  // Getters
  String get nome => _nome;
  String get mensagem => _mensagem;
  String get path_foto => _path_foto;
  String get userId => _userId;

  // Setters
  set nome(String value) => _nome = value;
  set mensagem(String value) => _mensagem = value;
  set path_foto(String value) => _path_foto = value;
  set userId(String value) => _userId = value;
}
