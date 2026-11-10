import 'dart:convert';
import 'package:http/http.dart' as http;

class CepAddressResult {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;
  final bool erro;

  const CepAddressResult({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
    this.erro = false,
  });

  factory CepAddressResult.fromJson(Map<String, dynamic> json) {
    if (json['erro'] == true || json['erro'] == 'true') {
      return const CepAddressResult(
        cep: '',
        logradouro: '',
        complemento: '',
        bairro: '',
        localidade: '',
        uf: '',
        erro: true,
      );
    }
    return CepAddressResult(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
      erro: false,
    );
  }
}

class CepService {
  static Future<CepAddressResult?> searchCep(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) return null;

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = CepAddressResult.fromJson(data);
        if (result.erro) return null;
        return result;
      }
    } catch (_) {
      // Fallback silencioso
    }
    return null;
  }
}
