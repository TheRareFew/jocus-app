import logging
from openai import OpenAI
from firebase_functions import https_fn
import os

logger = logging.getLogger(__name__)

@https_fn.on_call()
def generate_beat_script(req: https_fn.Request) -> https_fn.Response:
    """Generate a script for a comedy beat based on the structure context."""
    try:
        # Get data from request
        data = req.data
        beat_type = data.get('beatType')
        beat_description = data.get('description')
        previous_beats = data.get('previousBeats', [])
        
        # Create context from previous beats
        context = "\n".join([
            f"{beat['type']}: {beat['description']}"
            for beat in previous_beats
        ])
        
        # Construct prompt
        prompt = f"""Context of previous beats in the comedy structure:
{context}

Generate a natural, conversational script for this beat:
Type: {beat_type}
Description: {beat_description}

Keep it concise and natural, as if speaking to an audience."""

        # Initialize OpenAI client
        client = OpenAI(api_key=os.environ.get('OPENAI_API_KEY'))
        
        # Generate script
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a comedy writer helping create natural, conversational scripts for standup comedy bits."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=200,
            temperature=0.7
        )
        
        generated_script = response.choices[0].message.content.strip()
        
        return {"script": generated_script}
        
    except Exception as e:
        logger.error(f"Error generating script: {str(e)}")
        return https_fn.Response(
            {"error": str(e)}, 
            status=500
        ) 