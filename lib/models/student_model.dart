class StudentModel {
  String name;
  String matricula;
  bool isPresent;
  bool zeroGrade;

  StudentModel({
    required this.name,
    required this.matricula,
    this.isPresent = true,
    this.zeroGrade = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'matricula': matricula,
      'isPresent': isPresent,
      'zeroGrade': zeroGrade,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      name: map['name'] ?? '',
      matricula: map['matricula'] ?? '',
      isPresent: map['isPresent'] ?? true,
      zeroGrade: map['zeroGrade'] ?? false,
    );
  }
}
