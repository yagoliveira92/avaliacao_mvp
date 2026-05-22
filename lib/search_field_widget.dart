import 'package:flutter/material.dart';

class SearchFieldWidget extends StatelessWidget {
  const SearchFieldWidget({
    required this.searchController,
    required this.onChanged,
    super.key,
  });

  final TextEditingController searchController;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: "Pesquisar equipe ou líder...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white60),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: onChanged,
    );
  }
}
