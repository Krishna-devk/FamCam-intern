from fastapi import APIRouter, Depends, Query
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date
from database import get_db
from models.service import Service
from schemas.service import ServiceResponse
from schemas.slot import SlotResponse
from services.slot_service import get_available_slots

router = APIRouter()

@router.get("/services", response_model=List[ServiceResponse])
async def get_services(q: Optional[str] = None, db: AsyncSession = Depends(get_db)):
    query = select(Service)
    if q:
        query = query.where(Service.name.ilike(f"%{q}%"))
    result = await db.execute(query)
    services = result.scalars().all()
    return services

@router.get("/slots/available", response_model=SlotResponse)
async def fetch_slots(
    service_id: int = Query(...),
    target_date: date = Query(..., alias="date"),
    patient_id: int = Query(...),
    db: AsyncSession = Depends(get_db)
):
    return await get_available_slots(
        service_id=service_id,
        target_date=target_date,
        patient_id=patient_id,
        db=db
    )
