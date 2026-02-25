class Usuario{

  late String _nome;
  late String _email;
  late String _senha;
  late String _codigo;


  Usuario();

  String get codigo => _codigo;
  String get senha  => _senha;
  String get email  => _email;
  String get nome   => _nome;

  set codigo(String value) {_codigo = value;}
  set senha(String value)  {_senha = value;}
  set email(String value)  {_email = value;}
  set nome(String value)   {_nome = value;}

}