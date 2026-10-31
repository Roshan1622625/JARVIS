# JARVIS

A macOS study assistant built with SwiftUI, with a Python FastAPI backend for AI chat.

## Project structure

The repository is intended to contain the Xcode macOS app and the `backend/` folder.

## Backend setup

1. Install Python 3 and create a virtual environment inside `backend/`.
2. Install the dependencies listed in `backend/requirements.txt`.
3. Set your API key as an environment variable named `LLM_KIWI_API_KEY`. Do not commit your real API key or any `.env` file.
4. From the `backend/` directory, start the API with:

   ```bash
   uvicorn main:app --host 127.0.0.1 --port 3000
   ```

5. Run the macOS app from Xcode. The current Swift client is configured to call `http://127.0.0.1:3000/chat`, so the backend must be running on the same Mac.

## Notes

- Keep secrets, virtual environments, Python cache files, and Xcode build output out of Git.
- Add the Xcode project (`.xcodeproj`), Swift source files, and `Assets.xcassets` to this repository when publishing the full app.
- Check that the app's privacy usage descriptions are configured in Xcode for any speech recognition or microphone features.
