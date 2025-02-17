import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:jocus_app/widgets/comedy_structure_card.dart';
import 'package:provider/provider.dart';
import 'package:jocus_app/providers/auth_provider.dart';

class TrendingFormatsScreen extends StatelessWidget {
  const TrendingFormatsScreen({Key? key}) : super(key: key);

  Future<void> _copyStructure(BuildContext context, ComedyStructure structure) async {
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    final personalCopy = structure.createPersonalCopy(userId);
    
    // Save to user's personal collection
    final userStructuresRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('comedy_structures');
    
    final docRef = await userStructuresRef.add(personalCopy.toMap());
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comedy structure copied to your library')),
      );
      
      // Navigate to edit screen with the copied structure
      Navigator.pushReplacementNamed(
        context,
        '/creator/edit-comedy-structure',
        arguments: {
          'structure': personalCopy.copyWith(id: docRef.id),
          'userId': userId,
        },
      );
    }
  }

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
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ComedyStructureCard(
                      structure: structure,
                      showEditButton: false,
                      autoStart: false,
                      overlay: false,
                      onSave: () => _copyStructure(context, structure),
                    ),
                    ButtonBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy to My Library'),
                          onPressed: () => _copyStructure(context, structure),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}