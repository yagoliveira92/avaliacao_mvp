import 'package:avaliacao_mvp/models/student_model.dart';

class TeamModel {
  String id;
  String projectName;
  String leaderName;
  List<StudentModel> members;
  Map<String, double> scores;
  double finalScore;
  String comments;
  bool isEvaluated;

  TeamModel({
    required this.id,
    required this.projectName,
    required this.leaderName,
    required this.members,
    this.scores = const {},
    this.finalScore = 0.0,
    this.comments = '',
    this.isEvaluated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'leaderName': leaderName,
      'members': members.map((x) => x.toMap()).toList(),
      'scores': scores,
      'finalScore': finalScore,
      'comments': comments,
      'isEvaluated': isEvaluated,
    };
  }

  factory TeamModel.fromMap(String id, Map<String, dynamic> map) {
    return TeamModel(
      id: id,
      projectName: map['projectName'] ?? 'Sem Nome',
      leaderName: map['leaderName'] ?? 'Desconhecido',
      members: List<StudentModel>.from(
        (map['members'] as List<dynamic>? ?? []).map(
          (x) => StudentModel.fromMap(x),
        ),
      ),
      scores: Map<String, double>.from(map['scores'] ?? {}),
      finalScore: (map['finalScore'] ?? 0.0).toDouble(),
      comments: map['comments'] ?? '',
      isEvaluated: map['isEvaluated'] ?? false,
    );
  }
}
