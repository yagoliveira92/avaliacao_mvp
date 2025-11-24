import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorModel {
  final String id; // Será a Matrícula (ID do documento)
  final String nome;

  ProfessorModel({required this.id, required this.nome});

  // --- CONVERTER DO FIREBASE (Map) PARA O OBJETO (Professor) ---
  // Usamos 'String id' separadamente pois o ID do documento vem fora do map de dados
  factory ProfessorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ProfessorModel(
      id: doc.id, // A matrícula é o ID do documento
      nome: data['nome'] ?? 'Professor Sem Nome',
    );
  }

  // --- CONVERTER DO OBJETO (Professor) PARA O FIREBASE (Map) ---
  Map<String, dynamic> toMap() {
    return {'nome': nome};
  }

  // Método auxiliar para cópia (útil para edição)
  ProfessorModel copyWith({String? name, String? email, String? role}) {
    return ProfessorModel(id: id, nome: name ?? nome);
  }
}
