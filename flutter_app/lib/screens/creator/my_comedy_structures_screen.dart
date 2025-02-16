import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:jocus_app/models/comedy_structure.dart';
import 'package:jocus_app/providers/auth_provider.dart';
import 'package:jocus_app/widgets/comedy_structure_card.dart';
import 'package:jocus_app/screens/viewer/feed_screen.dart';

class MyComedyStructuresScreen extends StatelessWidget {
  final bool selectionMode;

  const MyComedyStructuresScreen({
    Key? key,
    this.selectionMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your comedy structures'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selectionMode ? 'Select Comedy Structure' : 'My Comedy Structures'),
        actions: [
          if (!selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () async {
                if (context.mounted) {
                  Navigator.pushNamed(context, '/viewer/feed');
                }
              },
              tooltip: 'Watch Feed',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final now = DateTime.now();
                final blankStructure = ComedyStructure(
                  id: FirebaseFirestore.instance.collection('temp').doc().id, // Generate a temporary ID
                  title: '',
                  description: '',
                  timeline: [],
                  metrics: {},
                  metadata: {},
                  authorId: userId,
                  isTemplate: false,
                  createdAt: now,
                  updatedAt: now,
                  reactions: [],
                );
                
                Navigator.pushNamed(
                  context,
                  '/creator/edit-comedy-structure',
                  arguments: {
                    'structure': blankStructure,
                    'userId': userId,
                  },
                );
              },
              tooltip: 'Create New Comedy Structure',
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('comedy_structures')
            .orderBy('updatedAt', descending: true)
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

          if (structures.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No comedy structures yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      final blankStructure = ComedyStructure(
                        id: FirebaseFirestore.instance.collection('temp').doc().id,
                        title: '',
                        description: '',
                        timeline: [],
                        metrics: {},
                        metadata: {},
                        authorId: userId,
                        isTemplate: false,
                        createdAt: now,
                        updatedAt: now,
                        reactions: [],
                      );
                      
                      Navigator.pushNamed(
                        context,
                        '/creator/edit-comedy-structure',
                        arguments: {
                          'structure': blankStructure,
                          'userId': userId,
                        },
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Comedy Structure'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: structures.length,
            itemBuilder: (context, index) {
              final structure = structures[index];
              return InkWell(
                onTap: selectionMode
                    ? () => Navigator.pop(context, structure)
                    : null,
                child: Dismissible(
                  key: Key(structure.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: !selectionMode ? DismissDirection.endToStart : DismissDirection.none,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Comedy Structure'),
                        content: const Text(
                          'Are you sure you want to delete this comedy structure? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('comedy_structures')
                        .doc(structure.id)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comedy structure deleted'),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ComedyStructureCard(
                          structure: structure,
                          showEditButton: !selectionMode,
                        ),
                        if (selectionMode)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Center(
                              child: Text(
                                'Tap to select',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
