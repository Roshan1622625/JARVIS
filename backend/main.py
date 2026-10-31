from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from openai import OpenAI
import os

load_dotenv()

app = FastAPI(title="JARVIS")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=api_key) if api_key else None


@app.get("/")
def home():
    return {
        "status": "online",
        "assistant": "JARVIS",
        "message": "JARVIS backend is operational."
    }


@app.post("/chat")
async def chat(data: dict):
    message = data.get("message", "")

    if not message:
        return {"reply": "I didn't receive a message."}

    if client is None:
        return {"reply": "My AI system hasn't been connected yet."}

    try:
        response = client.responses.create(
            model="gpt-5",
            instructions="""
You are JARVIS, a sophisticated personal AI assistant.

Be intelligent, calm, professional and concise.

You are speaking to the user through a macOS application,
so keep responses natural and reasonably short.

Never claim that you performed an action unless the application
actually performed that action.
""",
            input=message
        )

        return {"reply": response.output_text}

    except Exception as error:
        print("JARVIS ERROR:", error)
        return {
            "reply": "I encountered an error connecting to my AI system."
        }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=3000,
        reload=True
    )
