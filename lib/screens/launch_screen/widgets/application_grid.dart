import 'package:flutter/material.dart';
import 'package:nitris/core/models/application.dart';
import 'application_card.dart';

class ApplicationGrid extends StatelessWidget {
  const ApplicationGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine orientation to decide grid layout.
    final Orientation orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 3 : 5;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        itemCount: applications.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1, // Ensures square tiles.
        ),
        itemBuilder: (context, index) =>
            ApplicationCard(application: applications[index]),
      ),
    );
  }
}
