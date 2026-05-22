import 'package:flutter/material.dart';

class CardDashboardWidget extends StatelessWidget {
  const CardDashboardWidget({
    required this.title,
    required this.leaderName,
    required this.isEvaluated,
    required this.onTap,
    super.key,
  });

  final String title;
  final String leaderName;
  final bool isEvaluated;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Líder: $leaderName'),
        trailing: isEvaluated
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.pending, color: Colors.orange),
        onTap: onTap,
      ),
    );
    ;
  }
}
