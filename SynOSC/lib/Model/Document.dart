// class Document{
//
//   String info1 = 'TIPO';
//   String info2 = 'NOME';
//   String info3 = 'STATUS';
//   String info4 = 'SOLICITADO POR';
//
//   String _conteudo1;
//   String _conteudo2;
//   String _conteudo3;
//   String _conteudo4;
//
//   int _tipo;
//
//
//   Document(this._conteudo1, this._conteudo2, this._conteudo3, this._conteudo4, this._tipo);
//
//
//
//   String get conteudo1 => _conteudo1;
//   String get conteudo2 => _conteudo2;
//   String get conteudo3 => _conteudo3;
//   String get conteudo4 => _conteudo4;
//
//   int get tipo => _tipo;
//
//
//
//   set conteudo1(String value) {_conteudo1 = value;}
//   set conteudo2(String value) {_conteudo2 = value;}
//   set conteudo3(String value) {_conteudo3 = value;}
//   set conteudo4(String value) {_conteudo4 = value;}
//
//   set tipo(int value) {_tipo = value;}
//
//
// }


class Document {
  // Atributos de Conteúdo
  final String nome;
  final String tipoDocumento;
  final String status;
  final String solicitadoPor;
  final DateTime data;
  final String titulo;

  // Atributos fixos (etiquetas)
  static const String infoNome          = 'Beneficiário';
  static const String infoTipoDocumento = 'Tipo';
  static const String infoStatus        = 'Status';
  static const String infoSolicitadoPor = 'Solicitado Por';
  static const String infoData          = 'Data';
  static const String infoTitulo        = 'Título';

  const Document({
    required this.nome,
    required this.tipoDocumento,
    required this.status,
    required this.solicitadoPor,
    required this.data,
    required this.titulo,
  });
}

