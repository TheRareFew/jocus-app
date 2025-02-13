from firebase_functions import https_fn
from firebase_admin import firestore
from datetime import datetime
from typing import Dict, List, Optional
from openai import OpenAI
import os
import json

def get_words_between(word_timings: List[Dict], start_time: float, end_time: float) -> str:
    """Get the words that occur between start_time and end_time."""
    words = []
    for word in word_timings:
        # Include word if it overlaps with the time range at all
        if (word['start'] <= end_time and word['end'] >= start_time):
            words.append(word['word'])
    return ' '.join(words)

def find_word_boundaries(word_timings: List[Dict], words: List[str]) -> Dict[str, float]:
    """Find the start time of the first word and end time of the last word in a script."""
    # Convert words to lowercase for matching
    target_words = [w.lower() for w in words]
    
    # Find the first and last word indices
    first_word_time = None
    last_word_time = None
    
    # Create a sliding window of words from the timing data
    for i in range(len(word_timings)):
        current_word = word_timings[i]['word'].lower()
        if current_word == target_words[0] and first_word_time is None:
            first_word_time = word_timings[i]['start']
        if current_word == target_words[-1]:
            last_word_time = word_timings[i]['end']
            
    if first_word_time is None or last_word_time is None:
        # Fallback if exact match fails
        return {'start': word_timings[0]['start'], 'end': word_timings[-1]['end']}
        
    return {'start': first_word_time, 'end': last_word_time}

def get_gpt_beats(transcript: str, word_timings: List[Dict]) -> List[Dict]:
    """Use GPT-4o-mini to analyze transcript and identify comedy beats."""
    client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    
    prompt = f"""Analyze this comedy transcript and identify the setup and punchline.

    IMPORTANT RULES:
    1. You MUST output exactly TWO beats: one setup and one punchline
    2. The setup should establish context or ask a question - it's the part that creates anticipation
    3. The punchline delivers the humor by subverting expectations or providing an unexpected answer
    4. Each beat MUST have a clear description of its role in the joke
    5. Make sure you keep track of the beginning and end words of each beat to add a duration.
    
    Output ONLY valid JSON with this structure:
    {{
        "beats": [
            {{
                "type": "setup",
                "description": "description of how this setup builds anticipation",
                "script": "exact words from transcript for setup",
                "durationSeconds": 5
            }},
            {{
                "type": "punchline",
                "description": "description of how this punchline delivers the humor",
                "script": "exact words from transcript for punchline",
                "durationSeconds": 2
            }}
        ]
    }}
    
    Transcript: {transcript}"""
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7
    )
    
    try:
        beats = json.loads(response.choices[0].message.content)['beats']
        if len(beats) != 2:
            print("Error: GPT did not return exactly 2 beats")
            return []
        return beats
    except Exception as e:
        print(f"Error parsing GPT response: {str(e)}")
        return []

@https_fn.on_call()
def analyze_joke_transcript(req: https_fn.CallableRequest) -> Dict:
    """Analyze transcript to create a comedy structure."""
    data = req.data
    transcript = data.get('transcript', '')
    word_timings = data.get('wordTimings', [])
    user_id = data.get('userId', '')
    
    if not transcript or not word_timings or not user_id:
        raise ValueError("Missing required data")
    
    # Get beats from GPT
    gpt_beats = get_gpt_beats(transcript, word_timings)
    
    # Create comedy structure
    structure = {
        'title': 'Generated Comedy Structure',
        'description': 'Automatically generated from transcript analysis',
        'timeline': gpt_beats,
        'authorId': user_id,
        'isTemplate': False,
        'createdAt': datetime.now(),
        'updatedAt': datetime.now(),
        'metrics': {},
        'metadata': {},
        'reactions': []
    }
    
    # Save to Firestore
    db = firestore.client()
    doc_ref = db.collection('users').document(user_id).collection('comedy_structures').document()
    doc_ref.set(structure)
    
    # Return both the ID and the complete structure with scripts
    return {
        'id': doc_ref.id, 
        'structure': structure,
        'timeline': gpt_beats  # Include timeline separately for immediate access
    }
