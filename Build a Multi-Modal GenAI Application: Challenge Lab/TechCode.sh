
#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE- INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

# Instruction for Region Input
read -p "${CYAN_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
echo

# Fetch GCP Project ID
ID="$(gcloud projects list --format='value(PROJECT_ID)')"

# Generate Image Python Script
cat > GenerateImage.py <<EOF_END
import argparse
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
    project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
    """Generate an image using a text prompt.
    Args:
      project_id: Google Cloud project ID, used to initialize Vertex AI.
      location: Google Cloud region, used to initialize Vertex AI.
      output_file: Local path to the output image file.
      prompt: The text prompt describing what you want to see."""

    vertexai.init(project=project_id, location=location)
    model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
    images = model.generate_images(
        prompt=prompt,
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )
    images[0].save(location=output_file)
    return images

generate_image(
    project_id='$ID',
    location='$REGION',
    output_file='image.jpeg',
    prompt='Create an image containing a bouquet of 2 sunflowers and 3 roses',
)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Generating an image of flowers... Please wait.${RESET_FORMAT}"
/usr/bin/python3 /home/student/GenerateImage.py
echo "${GREEN_TEXT}${BOLD_TEXT}Image generated successfully! Check 'image.jpeg' in your working directory.${RESET_FORMAT}"

# Multimodal Analysis Script
cat > genai.py <<EOF_END
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Image, Content
import sys

def analyze_bouquet_image(project_id: str, location: str):
    # Initialize Vertex AI
    vertexai.init(project=project_id, location=location)
    
    # Load the Gemini multimodal model
    model = GenerativeModel("gemini-2.0-flash-001")
    
    # Load image part
    image_path = "/home/student/image.jpeg"
    image_part = Part.from_image(Image.load_from_file(image_path))
    
    # Initial image analysis with streaming
    print("📷 Image Analysis: ", end="", flush=True)
    response_stream = model.generate_content(
        [
            image_part,
            Part.from_text("What is shown in this image?")
        ],
        stream=True
    )
    
    # Print streamed response
    full_response = ""
    for chunk in response_stream:
        if chunk.text:
            print(chunk.text, end="", flush=True)
            full_response += chunk.text
    print("\n")
    
    # Start chat with proper history format
    chat_history = [
        Content(role="user", parts=[image_part, Part.from_text("What is shown in this image?")]),
        Content(role="model", parts=[Part.from_text(full_response)])
    ]
    
    chat = model.start_chat(history=chat_history)
    
    print("\n🎤 Chat with Gemini (type 'exit' to quit):")
    
    while True:
        user_input = input("You: ")
        if user_input.lower() == "exit":
            break
        
        try:
            # Send message with streaming
            response_stream = chat.send_message(user_input, stream=True)
            print("Gemini: ", end="", flush=True)
            
            for chunk in response_stream:
                if chunk.text:
                    print(chunk.text, end="", flush=True)
            print()
            
        except Exception as e:
            print(f"Error: {e}")
            break

# Set your project and location
project_id = "$ID"
location = "$REGION"

# Run the function
analyze_bouquet_image(project_id, location)
EOF_END

echo "${YELLOW_TEXT}${BOLD_TEXT}Analyzing the generated image with Gemini...${RESET_FORMAT}"
/usr/bin/python3 /home/student/genai.py

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
