import sys
import os

# Append current working directory to path to ensure proper imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers.slots import router as slots_router
from routers.checkout import router as checkout_router
from exceptions import BookingConflictError, booking_conflict_exception_handler

app = FastAPI(
    title="FamCare API",
    description="Multi-Service Bulk Scheduler API",
    version="1.0"
)

# Exception handlers
app.add_exception_handler(BookingConflictError, booking_conflict_exception_handler)

# CORS middleware for local Flutter web or emulator connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production specify origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(slots_router)
app.include_router(checkout_router)

@app.get("/health")
def health():
    return {"status": "ok"}
