import 'package:avaliacao_mvp/screens/dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/professor_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _matriculaController = TextEditingController();
  bool _isLoading = false;
  String _error = '';

  static const String _kMatriculaKey = 'professor_matricula';

  @override
  void initState() {
    super.initState();
    _checkPersistentLogin();
  }

  Future<void> _checkPersistentLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMatricula = prefs.getString(_kMatriculaKey);

      if (savedMatricula != null && savedMatricula.isNotEmpty) {
        // Tenta logar automaticamente com a matrícula salva
        await _performLogin(savedMatricula);
      }
    } catch (e) {
      debugPrint('Erro ao verificar login persistente: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    final matricula = _matriculaController.text.trim();
    if (matricula.isEmpty) {
      setState(() {
        _error = 'Digite sua matrícula.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    await _performLogin(matricula, saveToPrefs: true);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performLogin(
    String matricula, {
    bool saveToPrefs = false,
  }) async {
    try {
      // Verifica na coleção de professores permitidos
      // A coleção deve usar a matrícula como ID do documento para facilitar
      final doc = await FirebaseFirestore.instance
          .collection('professors_allowlist')
          .doc(matricula)
          .get();

      if (doc.exists) {
        if (saveToPrefs) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kMatriculaKey, matricula);
        }

        final professor = ProfessorModel.fromFirestore(doc);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(professor: professor),
            ),
          );
        }
      } else {
        setState(() => _error = 'Matrícula não encontrada ou não autorizada.');
      }
    } catch (e) {
      setState(() => _error = 'Erro de conexão: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 64, color: Color(0xFF0D47A1)),
                  const SizedBox(height: 16),
                  const Text(
                    "Acesso do Professor",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Avaliação Final - MVP",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _matriculaController,
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("ENTRAR"),
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
