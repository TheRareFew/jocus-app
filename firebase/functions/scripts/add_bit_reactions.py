import firebase_admin
from firebase_admin import credentials, firestore
import random
from datetime import datetime, timedelta
import os

# Initialize Firebase Admin
cred = credentials.Certificate(os.path.join(os.path.dirname(__file__), '..', 'service-account-key.json'))
firebase_admin.initialize_app(cred)
db = firestore.client()

# Reaction types and their probabilities (out of 100)
REACTION_TYPES = {
    'rofl': 40,    # Most common
    'smirk': 30,   # Second most common
    'eyeroll': 20, # Less common
    'vomit': 10    # Rare
}

def generate_random_reactions(bit_id, num_reactions=50):
    """Generate random reactions for a bit."""
    reactions = []
    base_time = datetime.now() - timedelta(days=7)  # Spread over last week
    
    for _ in range(num_reactions):
        # Random timestamp within the last week
        timestamp = base_time + timedelta(
            days=random.random() * 7,
            seconds=random.randint(0, 86400)
        )
        
        # Random reaction type based on probabilities
        rand = random.randint(1, 100)
        cumulative = 0
        selected_type = None
        for reaction_type, probability in REACTION_TYPES.items():
            cumulative += probability
            if rand <= cumulative:
                selected_type = reaction_type
                break
        
        # Random timestamp in the video (0 to 1 minutes)
        video_timestamp = random.uniform(0, 60)
        
        reactions.append({
            'type': selected_type,
            'timestamp': video_timestamp,
            'userId': f'random_user_{random.randint(1, 100)}',
            'createdAt': timestamp
        })
    
    return reactions

def update_bit_analytics(bit_ref, reactions):
    """Update analytics for a bit based on reactions."""
    reaction_counts = {reaction_type: 0 for reaction_type in REACTION_TYPES}
    for reaction in reactions:
        reaction_counts[reaction['type']] += 1
    
    analytics_ref = bit_ref.collection('analytics').document('stats')
    analytics_ref.set({
        'totalReactions': len(reactions),
        'reactionCounts': reaction_counts,
        'viewCount': random.randint(len(reactions) * 2, len(reactions) * 10),  # Views are 2-10x reactions
        'lastUpdated': datetime.now()
    })

def add_reactions_to_bits(min_reactions=30, max_reactions=100):
    """Add random reactions to all bits in the database."""
    bits_ref = db.collection('bits')
    bits = bits_ref.stream()
    
    for bit in bits:
        print(f"Processing bit: {bit.id}")
        
        # Generate random number of reactions
        num_reactions = random.randint(min_reactions, max_reactions)
        reactions = generate_random_reactions(bit.id, num_reactions)
        
        # Add reactions in batches
        batch_size = 500
        for i in range(0, len(reactions), batch_size):
            batch = db.batch()
            batch_reactions = reactions[i:i + batch_size]
            
            for reaction in batch_reactions:
                reaction_ref = bit.reference.collection('reactions').document()
                batch.set(reaction_ref, reaction)
            
            batch.commit()
            print(f"Added batch of {len(batch_reactions)} reactions")
        
        # Update analytics
        update_bit_analytics(bit.reference, reactions)
        print(f"Updated analytics for bit {bit.id}")
        print(f"Total reactions added: {len(reactions)}")
        print("-" * 50)

if __name__ == "__main__":
    print("Starting to add reactions to bits...")
    add_reactions_to_bits()
    print("Finished adding reactions to bits!")
