import 'package:avaliacao_mvp/models/student_model.dart';
import 'package:avaliacao_mvp/models/team_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GradesResultScreen extends StatefulWidget {
  const GradesResultScreen({super.key});

  @override
  State<GradesResultScreen> createState() => _GradesResultScreenState();
}

class _GradesResultScreenState extends State<GradesResultScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultados e Notas Finais"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- CAMPO DE BUSCA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Equipe ou Nome do Aluno...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = "");
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // --- LISTA DE TIMES ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Erro ao carregar times"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;

                // --- NOVA LÓGICA DE FILTRAGEM ---
                final filteredDocs = allDocs.where((doc) {
                  // Se não houver busca, exibe tudo
                  if (_searchText.isEmpty) return true;

                  final data = doc.data() as Map<String, dynamic>;

                  // 1. Verifica Nome do Projeto
                  final projectName = (data['projectName'] ?? '')
                      .toString()
                      .toLowerCase();
                  bool matchesTeam = projectName.contains(_searchText);

                  // 2. Verifica Nome dos Alunos
                  bool matchesStudent = false;
                  if (data['members'] != null) {
                    final membersList = List.from(data['members']);
                    for (var member in membersList) {
                      final studentName = (member['name'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (studentName.contains(_searchText)) {
                        matchesStudent = true;
                        break; // Encontrou um aluno, já serve para exibir o grupo
                      }
                    }
                  }

                  // Retorna verdadeiro se encontrar no Time OU no Aluno
                  return matchesTeam || matchesStudent;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchText.isEmpty
                              ? "Nenhum grupo cadastrado."
                              : "Nenhum resultado para \"$_searchText\".",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final teamDoc = filteredDocs[index];
                    final team = TeamModel.fromMap(
                      teamDoc.id,
                      teamDoc.data() as Map<String, dynamic>,
                    );

                    return _TeamGradeCard(team: team);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// O Widget do Card permanece o mesmo, focado apenas em calcular e exibir
class _TeamGradeCard extends StatelessWidget {
  final TeamModel team;

  const _TeamGradeCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(team.id)
          .collection('evaluations')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(team.projectName),
              trailing: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final evaluations = snapshot.data!.docs;

        // --- CÁLCULO ---
        double totalSum = 0.0;
        int evaluatorCount = evaluations.length;
        Map<String, List<String>> studentsZeroedBy = {};

        for (var doc in evaluations) {
          final data = doc.data() as Map<String, dynamic>;
          // Soma a nota (Escala 0-10 baseada nos pesos originais)
          totalSum += (data['finalScore'] ?? 0.0) as double;

          // Verifica zeramento
          if (data['memberStatus'] != null) {
            final membersStatus = List.from(data['memberStatus']);
            for (var m in membersStatus) {
              if (m['zeroGrade'] == true) {
                final matricula = m['matricula'];
                final profName = data['professorName'] ?? 'Desconhecido';

                if (!studentsZeroedBy.containsKey(matricula)) {
                  studentsZeroedBy[matricula] = [];
                }
                studentsZeroedBy[matricula]!.add(profName);
              }
            }
          }
        }

        // 1. Calcula a média na escala original (0-10)
        double averageScore10 = evaluatorCount > 0
            ? totalSum / evaluatorCount
            : 0.0;

        // 2. Converte para a escala 0-5
        double finalScore5 = averageScore10 / 2;

        // Regra de aprovação visual (70% de 5.0 = 3.5)
        bool isApproved = finalScore5 >= 3.5;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            shape: const Border(),
            title: Text(
              team.projectName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              evaluatorCount > 0
                  ? "$evaluatorCount avaliações"
                  : "Aguardando notas...",
              style: TextStyle(
                color: evaluatorCount > 0
                    ? Colors.grey[700]
                    : Colors.orange[800],
                fontWeight: evaluatorCount == 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: evaluatorCount > 0
                    ? (isApproved ? Colors.green[50] : Colors.red[50])
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: evaluatorCount > 0
                      ? (isApproved
                            ? Colors.green.shade300
                            : Colors.red.shade300)
                      : Colors.grey.shade400,
                ),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: evaluatorCount > 0
                        ? (isApproved ? Colors.green[800] : Colors.red[800])
                        : Colors.grey[600],
                  ),
                  children: [
                    TextSpan(
                      text: evaluatorCount > 0
                          ? finalScore5.toStringAsFixed(2)
                          : "-",
                    ),
                    if (evaluatorCount > 0)
                      const TextSpan(
                        text: " / 5.0",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 18,
                          color: Colors.blue[800],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Desempenho Individual (Escala 0-5)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(List<StudentModel>.from(team.members)
                          ..sort((a, b) => a.name
                              .toLowerCase()
                              .compareTo(b.name.toLowerCase())))
                        .map((member) {
                      final zeroedBy = studentsZeroedBy[member.matricula];
                      final isZeroed = zeroedBy != null && zeroedBy.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isZeroed ? Colors.red[50] : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      decoration: isZeroed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isZeroed
                                          ? Colors.red[900]
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "Mat: ${member.matricula}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (isZeroed)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        "⚠ Zerado por: ${zeroedBy.join(', ')}",
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              evaluatorCount == 0
                                  ? "-"
                                  : (isZeroed
                                        ? "0.0"
                                        : finalScore5.toStringAsFixed(2)),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isZeroed ? Colors.red : Colors.black87,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
