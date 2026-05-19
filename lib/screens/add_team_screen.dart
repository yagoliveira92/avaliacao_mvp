import 'package:avaliacao_mvp/models/student_model.dart';
import 'package:avaliacao_mvp/models/team_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _leaderNameController = TextEditingController();

  final List<TextEditingController> _studentNameControllers = [];
  final List<TextEditingController> _studentMatriculaControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addStudentField(); // Start with one student field
  }

  void _addStudentField() {
    setState(() {
      _studentNameControllers.add(TextEditingController());
      _studentMatriculaControllers.add(TextEditingController());
    });
  }

  void _removeStudentField(int index) {
    setState(() {
      _studentNameControllers[index].dispose();
      _studentMatriculaControllers[index].dispose();
      _studentNameControllers.removeAt(index);
      _studentMatriculaControllers.removeAt(index);
    });
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final List<StudentModel> members = [];
      for (int i = 0; i < _studentNameControllers.length; i++) {
        members.add(
          StudentModel(
            name: _studentNameControllers[i].text.trim(),
            matricula: _studentMatriculaControllers[i].text.trim(),
          ),
        );
      }

      final team = TeamModel(
        id: '', // Firestore will generate
        projectName: _projectNameController.text.trim(),
        leaderName: _leaderNameController.text.trim(),
        members: members,
        isEvaluated: false,
      );

      await FirebaseFirestore.instance.collection('teams').add(team.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipe adicionada com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao adicionar equipe: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Nova Equipe'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Projeto',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _leaderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Líder',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Integrantes da Equipe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...List.generate(_studentNameControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _studentNameControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _studentMatriculaControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Matrícula',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Obrigatório'
                                    : null,
                              ),
                            ),
                            if (_studentNameControllers.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeStudentField(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addStudentField,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Integrante'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveTeam,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'SALVAR EQUIPE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _leaderNameController.dispose();
    for (var controller in _studentNameControllers) {
      controller.dispose();
    }
    for (var controller in _studentMatriculaControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
