import 'package:avaliacao_mvp/card_dashboard_widget.dart';
import 'package:avaliacao_mvp/search_field_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:avaliacao_mvp/models/team_model.dart';
import 'package:avaliacao_mvp/models/professor_model.dart';
import 'package:avaliacao_mvp/screens/evaluation_form_screen.dart';
import 'package:avaliacao_mvp/screens/login_screen.dart';
import 'package:avaliacao_mvp/screens/grades_result_screen.dart';
import 'package:avaliacao_mvp/screens/add_team_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final ProfessorModel professor;

  const DashboardScreen({super.key, required this.professor});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _startSearch() {
    ModalRoute.of(
      context,
    )!.addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearch));

    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    _clearSearchQuery();

    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      _updateSearchQuery("");
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
    });
  }

  Widget _buildSearchField() {
    return SearchFieldWidget(
      onChanged: _updateSearchQuery,
      searchController: _searchController,
    );
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }

    return [
      IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('professor_matricula');

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField()
            : Text('Olá, ${widget.professor.nome}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: _buildActions(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar dados.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma equipe encontrada.'));
          }

          // Filtrar por busca
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final projectName = (data['projectName'] ?? "")
                .toString()
                .toLowerCase();
            final leaderName = (data['leaderName'] ?? "")
                .toString()
                .toLowerCase();
            final query = _searchQuery.toLowerCase();

            return projectName.contains(query) || leaderName.contains(query);
          }).toList();

          // Ordenar por nome
          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aName = (aData['projectName'] ?? '').toString().toLowerCase();
            final bName = (bData['projectName'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });

          if (filteredDocs.isEmpty) {
            return const Center(child: Text('Nenhum resultado para a busca.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final team = TeamModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('teams')
                    .doc(team.id)
                    .collection('evaluations')
                    .doc(widget.professor.id)
                    .snapshots(),
                builder: (context, evalSnapshot) {
                  final isEvaluated =
                      evalSnapshot.hasData && evalSnapshot.data!.exists;

                  return CardDashboardWidget(
                    title: team.projectName,
                    leaderName: team.leaderName,
                    isEvaluated: isEvaluated,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EvaluationFormScreen(
                            team: team,
                            professorId: widget.professor.id,
                            professorName: widget.professor.nome,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.bar_chart),
            label: 'Resultados',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GradesResultScreen(),
              ),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.group_add),
            label: 'Adicionar Equipe',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTeamScreen()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
