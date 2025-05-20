import 'dart:convert';
import 'package:http/http.dart' as http;

class KaspaApi {
  // CHANGE THIS to your local IP for real device testing!
  static const _baseUrl = 'http://94.130.57.236:3001/api';

  /// Generates a new Kaspa wallet via your backend.
  static Future<Map<String, String>> generateWallet() async {
    final response = await http.post(Uri.parse('$_baseUrl/generate_wallet'));
    print('generateWallet: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'address': data['address'] as String,
        'privateKey': data['privateKey'] as String,
      };
    } else {
      throw Exception('Failed to generate wallet: ${response.body}');
    }
  }

  /// Imports an existing Kaspa wallet (validates WIF and returns address).
  static Future<Map<String, String>> importWallet(String wif) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/import_wallet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'wif': wif}),
    );
    print('importWallet: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'address': data['address'] as String};
    } else {
      throw Exception('Invalid private key');
    }
  }

  /// Gets the balance for a Kaspa address.
  static Future<double> getBalance(String address) async {
    final response = await http.get(Uri.parse('$_baseUrl/balance?address=$address'));
    print('getBalance: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['balance'] as num).toDouble();
    } else {
      throw Exception('Failed to get balance: ${response.body}');
    }
  }

  /// Sends KASPA from your wallet to a destination address.
  static Future<String> sendKaspa(String fromWif, String to, String amount) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tx'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fromWif': fromWif, 'to': to, 'amount': amount}),
    );
    print('sendKaspa: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['txid'] != null) return data['txid'];
      throw Exception(data['error'] ?? 'Unknown error');
    } else {
      throw Exception('Failed to send KAS: ${response.body}');
    }
  }
}
