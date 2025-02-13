import firebase_admin
from firebase_admin import credentials, firestore
import os
from datetime import datetime

# Sample comedy structures data
COMEDY_STRUCTURES = [
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
    },
    {
        "title": "Dating App Adventures",
        "description": "Modern take on dating app experiences and mishaps",
        "timeline": [
            {
                "type": "setup",
                "description": "Scrolling through bizarre profile descriptions",
                "durationSeconds": 25,
                "details": {
                    "energy": "bemused",
                    "voiceTone": "incredulous"
                }
            },
            {
                "type": "punchline",
                "description": "Profile claims to be 'fluent in sarcasm'",
                "durationSeconds": 4,
                "details": {
                    "delivery": "sarcastic",
                    "expectedReaction": "relatable laugh"
                }
            },
            {
                "type": "pause",
                "description": "Dramatic pause while swiping",
                "durationSeconds": 2,
                "details": {
                    "purpose": "build anticipation"
                }
            },
            {
                "type": "callback",
                "description": "Match with someone equally sarcastic",
                "durationSeconds": 6,
                "details": {
                    "callbackTo": "sarcasm reference",
                    "timing": "unexpected"
                }
            }
        ],
        "metrics": {
            "laughDensity": 4.8,
            "audienceScore": 9.0,
            "peakReactionTimestamp": 31,
            "callbackEffectiveness": 0.88
        },
        "metadata": {
            "subject": "Modern Dating",
            "comedyStyle": "Observational",
            "duration": 37,
            "popularity": 96,
            "tags": ["dating apps", "millennial", "social media", "relationships"]
        }
    }
]

def init_firestore():
    # Get the path to the service account key relative to this script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    key_path = os.path.join(script_dir, '..', 'service-account-key.json')
    
    # Initialize Firebase Admin
    cred = credentials.Certificate(key_path)
    firebase_admin.initialize_app(cred)
    
    # Get Firestore client
    db = firestore.client()
    
    # Reference to comedy_structures collection
    collection_ref = db.collection('comedy_structures')
    
    # First, delete existing documents
    docs = collection_ref.stream()
    for doc in docs:
        print(f"Deleting existing document: {doc.id}")
        doc.reference.delete()
    
    # Add new structures
    for structure in COMEDY_STRUCTURES:
        # Add timestamp
        structure['createdAt'] = datetime.utcnow()
        
        # Add to Firestore
        doc_ref = collection_ref.add(structure)
        print(f"Added comedy structure: {structure['title']} (ID: {doc_ref[1].id})")
    
    print("\nFirestore initialization complete!")
    print(f"Added {len(COMEDY_STRUCTURES)} comedy structures")

if __name__ == "__main__":
    try:
        init_firestore()
    except Exception as e:
        print(f"Error initializing Firestore: {e}")
