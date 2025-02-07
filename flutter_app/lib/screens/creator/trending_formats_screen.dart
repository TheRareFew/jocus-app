import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:jocus_app/widgets/comedy_structure_card.dart';

class TrendingFormatsScreen extends StatelessWidget {
  const TrendingFormatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Comedy Structures'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comedy_structures')
            .orderBy('metadata.popularity', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final structures = snapshot.data?.docs
              .map((doc) => ComedyStructure.fromFirestore(doc))
              .toList() ?? [];

          return ListView.builder(
            itemCount: structures.length,
            itemBuilder: (context, index) {
              final structure = structures[index];
              return ComedyStructureCard(
                structure: structure,
                showEditButton: true,
                autoStart: false,
                overlay: false,
                onSave: () {
                  Navigator.pop(context); // Pop the trending formats screen after successful copy
                },
              );
            },
          );
        },
      ),
    );
  }
}