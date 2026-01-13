from fastapi import FastAPI
from apps.nexa_vision.router import router as vision_router

app = FastAPI(title="Nexa Agent")

# Mount routers
app.include_router(vision_router)

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}
