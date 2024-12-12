import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'application_card.dart';

class ApplicationGrid extends StatelessWidget {
  const ApplicationGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: GridView.builder(
        itemCount: applications.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8, // Added this parameter to make tiles taller
        ),
        itemBuilder: (context, index) =>
            ApplicationCard(application: applications[index]),
      ),
    );
  }
}
