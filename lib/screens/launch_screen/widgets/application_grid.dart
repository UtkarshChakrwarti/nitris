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

    return FutureBuilder<List<Application>>(
      future: getApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No applications available.'));
        }
        final apps = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            itemCount: apps.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8, // Allow card height to expand if needed.
            ),
            itemBuilder: (context, index) =>
                ApplicationCard(application: apps[index]),
          ),
        );
      },
    );
  }
}
