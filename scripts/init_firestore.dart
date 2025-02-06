import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final sampleStructures = [
  {
    "title": "Daily Routine Breakdown",
    "description": "A relatable bit about morning routines with strong callback potential",
    "timeline": [
      {
        "type": "setup",
        "description": "Establish morning routine context - hitting snooze button",
        "durationSeconds": 30,
        "details": {
          "energy": "calm",
          "voiceTone": "observational"
        }
      },
      {
        "type": "pause",
        "description": "Let audience relate to the situation",
        "durationSeconds": 2,
        "details": {
          "purpose": "build tension",
          "bodyLanguage": "knowing look"
        }
      },
      {
        "type": "punchline",
        "description": "Reveal twist about alarm clock collection",
        "durationSeconds": 5,
        "details": {
          "delivery": "quick",
          "expectedReaction": "surprise laugh"
        }
      },
      {
        "type": "callback",
        "description": "Reference back to first alarm while discussing evening routine",
        "durationSeconds": 8,
        "details": {
          "callbackTo": "snooze button",
          "timing": "end of bit"
        }
      }
    ],
    "metrics": {
      "laughDensity": 4.2,
      "audienceScore": 8.5,
      "peakReactionTimestamp": 35,
      "callbackEffectiveness": 0.9
    },
    "metadata": {
      "subject": "Daily Life",
      "comedyStyle": "Observational",
      "duration": 45,
      "popularity": 95,
      "tags": ["morning routine", "relatable", "callbacks"]
    }
  },
  {
    "title": "Tech Support Nightmare",
    "description": "Comedy bit about the absurdity of technical support calls",
    "timeline": [
      {
        "type": "setup",
        "description": "Set scene of calling tech support",
        "durationSeconds": 20,
        "details": {
          "energy": "frustrated",
          "voiceTone": "escalating"
        }
      },
      {
        "type": "pause",
        "description": "Wait for audience recognition",
        "durationSeconds": 2,
        "details": {
          "purpose": "audience connection"
        }
      },
      {
        "type": "punchline",
        "description": "Reveal support is actually a cat",
        "durationSeconds": 3,
        "details": {
          "delivery": "deadpan",
          "expectedReaction": "burst laugh"
        }
      },
      {
        "type": "pause",
        "description": "Let laughter build",
        "durationSeconds": 3,
        "details": {
          "purpose": "laugh break"
        }
      },
      {
        "type": "callback",
        "description": "Meow response to technical question",
        "durationSeconds": 5,
        "details": {
          "callbackTo": "cat reveal",
          "timing": "perfect timing"
        }
      }
    ],
    "metrics": {
      "laughDensity": 5.1,
      "audienceScore": 9.2,
      "peakReactionTimestamp": 28,
      "callbackEffectiveness": 0.95
    },
    "metadata": {
      "subject": "Technology",
      "comedyStyle": "Absurdist",
      "duration": 33,
      "popularity": 98,
      "tags": ["tech support", "cats", "frustration", "callbacks"]
    }
  }
];

Future<void> initializeFirestore() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  
  // Clear existing comedy structures
  final existingDocs = await firestore.collection('comedy_structures').get();
  for (var doc in existingDocs.docs) {
    batch.delete(doc.reference);
  }
  
  // Add sample structures
  for (var structure in sampleStructures) {
    final docRef = firestore.collection('comedy_structures').doc();
    batch.set(docRef, structure);
  }
  
  await batch.commit();
  print('Firestore initialized with sample comedy structures');
}

void main() async {
  try {
    await initializeFirestore();
  } catch (e) {
    print('Error initializing Firestore: $e');
  }
}
