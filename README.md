# JARVIS

A macOS study assistant built with SwiftUI, with a Python FastAPI backend for AI chat.

## Project structure

- `JARVIS.xcodeproj/` contains the macOS Xcode project.
- `macOS/` contains the SwiftUI app, chat, AI connection, and speech files.
- `backend/` contains the Python FastAPI service.

## Open the macOS app

1. Open `JARVIS.xcodeproj` in Xcode.
2. Select the **JARVIS** scheme and your Mac as the run destination.
3. Run the app.

The project uses the Swift files in `macOS/` directly. No separate iOS project is included.

## Start the AI backend

The Swift client calls `http://127.0.0.1:3000/chat`, so the backend must be running on the same Mac.

1. Open Terminal and move into the backend folder:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Set your API key in the environment. Do not commit the real key:
   ```bash
   export LLM_KIWI_API_KEY="your-api-key"
   ```
5. Start the API:
   ```bash
   uvicorn main:app --host 127.0.0.1 --port 3000
   ```
6. Keep that Terminal window open while using JARVIS.

## Notes

- Xcode will request microphone and speech-recognition permission when those features are used.
- Keep API keys, `.env` files, virtual environments, Python cache files, and Xcode build output out of Git.
- The project has not yet been built or tested on another Mac. Run it in Xcode and resolve any machine-specific signing or permission prompts.
