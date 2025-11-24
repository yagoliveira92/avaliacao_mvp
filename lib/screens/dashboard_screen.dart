import 'package:avaliacao_mvp/models/professor_model.dart';
import 'package:avaliacao_mvp/models/team_model.dart';
import 'package:avaliacao_mvp/screens/evaluation_form_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final ProfessorModel professor;

  const DashboardScreen({super.key, required this.professor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          "Painel de Avaliação",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "Olá, Prof ${professor.nome}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Assumindo que a coleção onde os times foram importados se chama 'teams'
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Erro ao carregar dados"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          // Ordena: Não avaliados primeiro
          final sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            final aEval = (a.data() as Map)['isEvaluated'] ?? false;
            final bEval = (b.data() as Map)['isEvaluated'] ?? false;
            if (aEval == bEval) return 0;
            return aEval ? 1 : -1;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final team = TeamModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: team.isEvaluated
                        ? Colors.green
                        : Colors.orange,
                    child: Icon(
                      team.isEvaluated ? Icons.check : Icons.edit,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    team.projectName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Líder: ${team.leaderName} • ${team.members.length} membros",
                  ),
                  trailing: team.isEvaluated
                      ? Text(
                          "${team.finalScore.toStringAsFixed(2)} pts",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluationFormScreen(
                          team: team,
                          professorId: professor.id,
                          professorName: professor.nome,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
