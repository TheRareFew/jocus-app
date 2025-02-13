import os
import logging
from firebase_functions import firestore_fn
from firebase_admin import initialize_app, storage, firestore
from openai import OpenAI
from firebase_functions import options

# Configure logging first
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Initialize Firebase
initialize_app()

# Import function implementations
from bits.transcripts import generate_transcript
from bits.comedy_structure import analyze_joke_transcript
from bits.hls_transcoder import on_bit_created
from bits.script_generator import generate_beat_script

# Log that functions are being registered
logger.info("Registering cloud functions...")

# Export functions
generate_transcript = firestore_fn.on_document_created(
    document="bits/{bitId}"
)(generate_transcript)

on_bit_created = firestore_fn.on_document_created(
    document="bits/{bitId}",
    memory=options.MemoryOption.GB_1,
    timeout_sec=540
)(on_bit_created)

analyze_joke_transcript = analyze_joke_transcript

generate_beat_script = generate_beat_script
