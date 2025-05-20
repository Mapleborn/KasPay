import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api.dart'; // Your API service

void main() {
  runApp(const KaspaWalletApp());
}

class KaspaWalletApp extends StatelessWidget {
  const KaspaWalletApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaspa Wallet',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kaspa Wallet')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome to Kaspa Wallet', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GenerateWalletPage()),
              ),
              child: const Text('Generate Wallet'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportWalletPage()),
              ),
              child: const Text('Import Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

class GenerateWalletPage extends StatefulWidget {
  const GenerateWalletPage({Key? key}) : super(key: key);

  @override
  _GenerateWalletPageState createState() => _GenerateWalletPageState();
}

class _GenerateWalletPageState extends State<GenerateWalletPage> {
  String? _address;
  String? _privateKey;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wallet = await KaspaApi.generateWallet();
      setState(() {
        _address = wallet['address'];
        _privateKey = wallet['privateKey'];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _continueToWallet() {
    if (_address != null && _privateKey != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WalletHomePage(address: _address!, privateKey: _privateKey!),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Wallet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Text('Error: $_error', style: const TextStyle(color: Colors.red))
                  : _address == null
                      ? ElevatedButton(
                          onPressed: _generate,
                          child: const Text('Generate Wallet'),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText('Private Key (hex): $_privateKey'),
                            const SizedBox(height: 16),
                            SelectableText('Kaspa Address: $_address'),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _continueToWallet,
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}

class ImportWalletPage extends StatefulWidget {
  const ImportWalletPage({Key? key}) : super(key: key);

  @override
  State<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final wifController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _importWallet() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final wif = wifController.text.trim();
    try {
      final result = await KaspaApi.importWallet(wif);
      final address = result['address']!;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => WalletHomePage(address: address, privateKey: wif),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = "Invalid private key!");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste your private key (hex):'),
              TextField(controller: wifController),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _importWallet,
                      child: const Text('Import'),
                    ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WalletHomePage extends StatefulWidget {
  final String address;
  final String privateKey;
  const WalletHomePage({Key? key, required this.address, required this.privateKey}) : super(key: key);

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  double? _balance;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _loading = true;
      _error = '';
      _balance = null;
    });
    try {
      final bal = await KaspaApi.getBalance(widget.address);
      setState(() => _balance = bal);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kaspa Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text('Your Address:', style: Theme.of(context).textTheme.bodyLarge),
            SelectableText(widget.address, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            Text('Balance:', style: Theme.of(context).textTheme.headlineSmall),
            if (_balance != null)
              Text('$_balance KAS', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))
            else if (_loading)
              const CircularProgressIndicator()
            else
              TextButton(onPressed: _loadBalance, child: const Text('Refresh Balance')),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendPage(
                        privateKey: widget.privateKey,
                        balance: _balance ?? 0,
                      ),
                    ),
                  ),
                  child: const Text('Send'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BuyPage()),
                  ),
                  child: const Text('Buy'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (_) => false,
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------- BUY PAGE ----------------------
class BuyPage extends StatelessWidget {
  const BuyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy Kaspa')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You will be redirected to a third-party site to purchase KAS.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                const url = 'https://changelly.com/buy-crypto'; // Change to your provider if needed
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch browser')),
                  );
                }
              },
              child: const Text('Continue to Buy'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------- SEND PAGE ----------------------
class SendPage extends StatefulWidget {
  final String privateKey;
  final double balance;
  const SendPage({Key? key, required this.privateKey, required this.balance}) : super(key: key);

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final toController = TextEditingController();
  final amountController = TextEditingController();
  String _result = '';
  String _error = '';
  bool _loading = false;

  Future<void> _send() async {
    setState(() {
      _error = '';
      _loading = true;
      _result = '';
    });
    final to = toController.text.trim();
    final amount = amountController.text.trim();
    try {
      final txid = await KaspaApi.sendKaspa(widget.privateKey, to, amount);
      setState(() => _result = 'Sent! TXID: $txid');
      toController.clear();
      amountController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Kaspa')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: toController,
              decoration: const InputDecoration(hintText: "Recipient Address"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: "Amount"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _send,
              child: const Text('Send'),
            ),
            if (_result.isNotEmpty)
              Text(_result, style: const TextStyle(color: Colors.green)),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
