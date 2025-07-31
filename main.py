import os
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException, Header
from pydantic import BaseModel
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get API key and port from environment variables
API_KEY = os.getenv("PUB_WAHA_KEY")
API_PORT = int(os.getenv("PUB_WAHA_PORT", "22100"))

# WAHA API configuration
WAHA_API_URL = os.getenv("WAHA_API_URL", "http://127.0.0.1:3000/api")

app = FastAPI(title="WAHA Secure API", description="Secure interface for WAHA API")

# Models
class TextMessage(BaseModel):
    chatId: str
    text: str
    reply_to: Optional[str] = None
    linkPreview: bool = True
    linkPreviewHighQuality: bool = False
    session: str = "default"

class MessageResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

# Authentication dependency
def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != API_KEY:
        raise HTTPException(
            status_code=401,
            detail="Invalid API Key"
        )
    return x_api_key

@app.post("/api/sendText", response_model=MessageResponse)
async def send_text(message: TextMessage, _: str = Depends(verify_api_key)):
    """
    Send a text message through the WAHA API
    """
    try:
        # Forward the request to WAHA API
        response = requests.post(
            f"{WAHA_API_URL}/sendText",
            json={
                "chatId": message.chatId,
                "text": message.text,
                "reply_to": message.reply_to,
                "linkPreview": message.linkPreview,
                "linkPreviewHighQuality": message.linkPreviewHighQuality,
                "session": message.session
            }
        )

        # Check if the request was successful
        if response.status_code in [200, 201]:
            # La API WAHA devuelve un objeto JSON con los detalles del mensaje
            # Si llegamos aquí, consideramos que el mensaje se envió correctamente
            message_id = ""

            # Intentamos extraer el ID del mensaje de la respuesta
            try:
                # Verificar si la respuesta tiene contenido antes de intentar parsear JSON
                if response.text.strip():
                    response_data = response.json()
                    if isinstance(response_data, dict):
                        if "id" in response_data:
                            message_id = response_data.get("id", {}).get("_serialized", "")
                        elif "_data" in response_data and "id" in response_data["_data"]:
                            message_id = response_data["_data"]["id"].get("_serialized", "")
            except Exception:
                # Si no podemos parsear la respuesta, no es un error crítico
                # ya que el código de estado indica éxito
                pass

            return MessageResponse(
                success=True,
                message="Message sent successfully",
                data={"message_id": message_id}
            )
        else:
            return MessageResponse(
                success=False,
                message=f"Failed to send message: HTTP {response.status_code}",
                data=None
            )
    except Exception as e:
        return MessageResponse(
            success=False,
            message=f"Error: {str(e)}",
            data=None
        )

@app.get("/health")
async def health_check():
    """
    Health check endpoint
    """
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=API_PORT, reload=True)
