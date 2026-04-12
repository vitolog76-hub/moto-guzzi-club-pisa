import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confermaPasswordController = TextEditingController();
  final _modelloMotoController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  
  static const Color guzziRed = Color(0xFF8B0000);

  Future<void> _register() async {
    if (_passwordController.text != _confermaPasswordController.text) {
      setState(() {
        _errorMessage = 'Le password non coincidono';
      });
      return;
    }

    if (_nomeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci il tuo nome';
      });
      return;
    }

    if (_modelloMotoController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Inserisci il modello della tua moto';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    bool success = await authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nomeController.text.trim(),
      _modelloMotoController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (BuildContext context) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Errore durante la registrazione. Email già esistente?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Unisciti al Club',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome e Cognome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _modelloMotoController,
                    decoration: const InputDecoration(
                      labelText: 'Modello Moto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confermaPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Conferma Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: guzziRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTRATI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}