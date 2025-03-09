import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'application_card.dart';

class ApplicationGrid extends StatelessWidget {
  const ApplicationGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        itemCount: applications.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9, // Adjusted to better fit the compact card.
        ),
        itemBuilder: (context, index) =>
            ApplicationCard(application: applications[index]),
      ),
    );
  }
}
