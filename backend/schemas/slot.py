from pydantic import BaseModel
from datetime import date, time
from typing import List

class CaregiverRef(BaseModel):
    id: int
    name: str

class SlotDetail(BaseModel):
    start_time: str # Format "HH:MM"
    end_time: str   # Format "HH:MM"
    available_caregivers: List[CaregiverRef]

class SlotResponse(BaseModel):
    service_id: int
    date: date
    duration_minutes: int
    available_slots: List[SlotDetail]
