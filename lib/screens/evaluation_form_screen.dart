import 'package:avaliacao_mvp/models/student_model.dart';
import 'package:avaliacao_mvp/models/team_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EvaluationFormScreen extends StatefulWidget {
  final TeamModel team;
  final String professorId;
  final String professorName;

  const EvaluationFormScreen({
    super.key,
    required this.team,
    required this.professorId,
    required this.professorName,
  });

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentsCtrl = TextEditingController();
  bool _isLoading = true;

  // PESOS (Weights) definidos no Edital
  final Map<String, double> _weights = {
    'Funcionalidade do Protótipo': 2.5,
    'Design e Usabilidade': 2.0,
    'Impacto e Engajamento': 2.0,
    'Documentação Completa': 1.5,
    'Apresentação Final': 1.5,
    'Trabalho em Equipe e Adaptação': 0.5,
  };

  // Controllers armazenam a nota de 0 a 10 digitada pelo professor
  final Map<String, TextEditingController> _controllers = {};

  late List<StudentModel> _localMembers;

  @override
  void initState() {
    super.initState();
    _weights.forEach((key, val) {
      _controllers[key] = TextEditingController();
    });

    _localMembers = widget.team.members
        .map(
          (m) => StudentModel(
            name: m.name,
            matricula: m.matricula,
            isPresent: true,
            zeroGrade: false,
          ),
        )
        .toList();

    _loadExistingEvaluation();
  }

  // --- LÓGICA DE CONVERSÃO ---

  // Converte Nota Ponderada (banco) -> Nota 0-10 (tela)
  String _weightedToDisplay(double storedValue, double weight) {
    if (weight == 0) return "0";
    double displayVal = (storedValue / weight) * 10;
    // Arredonda para 1 casa decimal para ficar bonito na tela (ex: 8.5)
    return displayVal.toStringAsFixed(1);
  }

  // Converte Nota 0-10 (tela) -> Nota Ponderada (banco)
  double _displayToWeighted(String text, double weight) {
    double inputVal = double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
    // Regra de três: (Nota / 10) * Peso
    return (inputVal / 10.0) * weight;
  }

  // ---------------------------

  Future<void> _loadExistingEvaluation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.team.id)
          .collection('evaluations')
          .doc(widget.professorId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final savedScores = Map<String, dynamic>.from(data['scores'] ?? {});

        setState(() {
          _commentsCtrl.text = data['comments'] ?? '';

          savedScores.forEach((key, val) {
            if (_controllers.containsKey(key)) {
              // O valor salvo é PONDERADO (ex: 1.25).
              // Precisamos converter para 0-10 (ex: 5.0) para mostrar ao prof.
              double weight = _weights[key] ?? 1.0;
              double storedVal = (val as num).toDouble();
              _controllers[key]!.text = _weightedToDisplay(storedVal, weight);
            }
          });

          if (data['memberStatus'] != null) {
            final statusList = List.from(data['memberStatus']);
            for (var status in statusList) {
              final index = _localMembers.indexWhere(
                (m) => m.matricula == status['matricula'],
              );
              if (index != -1) {
                _localMembers[index].isPresent = status['isPresent'] ?? true;
                _localMembers[index].zeroGrade = status['zeroGrade'] ?? false;
              }
            }
          }
        });
      }
    } catch (e) {
      print("Erro load: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateMyTotal() {
    double total = 0.0;
    _controllers.forEach((key, ctrl) {
      double weight = _weights[key] ?? 0.0;
      // Calcula o valor real baseado na nota 0-10
      double inputVal = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
      if (inputVal > 10) inputVal = 10;
      if (inputVal < 0) inputVal = 0;
      total += _displayToWeighted(ctrl.text, weight);
    });
    return total;
  }

  Future<void> _save() async {
    // 1. Validação
    if (!_formKey.currentState!.validate()) return;

    // --- CORREÇÃO DO ERRO ---
    // Remove o foco de qualquer campo de texto ativo.
    // Isso evita o erro "disposed EngineFlutterView" no Web.
    FocusScope.of(context).unfocus();

    // Guarda as referências do contexto ANTES da operação assíncrona
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // ------------------------

    setState(
      () => _isLoading = true,
    ); // Mostra loading (opcional, se quiser travar a tela)

    // Prepara os dados (Lógica original mantida)
    Map<String, double> scoresToSave = {};
    _controllers.forEach((key, ctrl) {
      double weight = _weights[key] ?? 0.0;
      scoresToSave[key] = _displayToWeighted(ctrl.text, weight);
    });

    List<Map<String, dynamic>> memberStatusToSave = _localMembers
        .map(
          (m) => {
            'matricula': m.matricula,
            'name': m.name,
            'isPresent': m.isPresent,
            'zeroGrade': m.zeroGrade,
          },
        )
        .toList();

    final myTotalScore = _calculateMyTotal();

    final evaluationData = {
      'professorName': widget.professorName,
      'professorId': widget.professorId,
      'scores': scoresToSave,
      'finalScore': myTotalScore,
      'comments': _commentsCtrl.text,
      'memberStatus': memberStatusToSave,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // Operação Assíncrona (Demorada)
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.team.id)
          .collection('evaluations')
          .doc(widget.professorId)
          .set(evaluationData);

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.team.id)
          .update({'hasEvaluations': true});

      // --- USO SEGURO PÓS-ASYNC ---
      // Usa as variáveis guardadas lá em cima, não o 'context' diretamente
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Avaliação salva com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pop();
    } catch (e) {
      // Se der erro e a tela ainda estiver aberta, avisa
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text("Avaliar: ${widget.team.projectName}"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placar
              Card(
                color: Colors.blue[50],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Nota Final Calculada",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "(Soma dos Pesos)",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: Listenable.merge(
                          _controllers.values.toList(),
                        ),
                        builder: (_, __) {
                          final score = _calculateMyTotal();
                          return Text(
                            "${score.toStringAsFixed(2)} / 10.0",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: score >= 7
                                  ? Colors.green
                                  : Colors.blue[900],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                "Critérios de Avaliação",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const Text(
                "Atribua uma nota de 0 a 10 para cada item.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(),

              ..._weights.entries.map((entry) {
                final key = entry.key;
                final weight = entry.value;
                final controller = _controllers[key]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Peso: $weight",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextFormField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: "0 a 10",
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                // Feedback visual se a nota for inválida
                                errorStyle: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return 'Obrigatório';
                                final n = double.tryParse(
                                  val.replaceAll(',', '.'),
                                );
                                if (n == null) return 'Inválido';
                                if (n < 0) return 'Min 0';
                                if (n > 10) return 'Máx 10';
                                return null;
                              },
                            ),
                            // Feedback de conversão em tempo real
                            const SizedBox(height: 4),
                            AnimatedBuilder(
                              animation: controller,
                              builder: (_, __) {
                                final val = _displayToWeighted(
                                  controller.text,
                                  weight,
                                );
                                return Text(
                                  "= ${val.toStringAsFixed(2)} pts",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Gestão de Presença
              const Text(
                "Integrantes",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const Divider(),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localMembers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = _localMembers[index];
                  return Container(
                    color: member.zeroGrade
                        ? Colors.red[50]
                        : Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: member.zeroGrade
                              ? TextDecoration.lineThrough
                              : null,
                          color: member.zeroGrade ? Colors.red : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        "Mat: ${member.matricula}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCheckbox("Presente", member.isPresent, (val) {
                            setState(() {
                              member.isPresent = val!;
                              if (!val) member.zeroGrade = true;
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildCheckbox("ZERAR", member.zeroGrade, (val) {
                            setState(() => member.zeroGrade = val!);
                          }, isDanger: true),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              const Text(
                "Feedback",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Observações sobre o desempenho da equipe...",
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    "FINALIZAR AVALIAÇÃO",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _save,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged, {
    bool isDanger = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
            color: isDanger ? Colors.red : Colors.black,
          ),
        ),
        SizedBox(
          height: 24,
          child: Checkbox(
            activeColor: isDanger ? Colors.red : const Color(0xFF0D47A1),
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
