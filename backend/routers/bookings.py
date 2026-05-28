from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models.booking import Booking
from models.user import User
from schemas.checkout import BookingDetail
from schemas.extra import CancelResponse
from typing import List

router = APIRouter(prefix="/bookings", tags=["Bookings"])

@router.get("", response_model=List[BookingDetail])
async def list_bookings(
    patient_id: int = Query(...),
    db: AsyncSession = Depends(get_db)
):
    stmt = (
        select(Booking)
        .where(Booking.patient_id == patient_id)
        .options(selectinload(Booking.service), selectinload(Booking.caregiver))
        .order_by(Booking.booking_date.desc(), Booking.start_time.desc())
    )
    result = await db.execute(stmt)
    bookings = result.scalars().all()
    
    details = []
    for b in bookings:
        cg_name = b.caregiver.name if b.caregiver else "Caregiver"
        
        details.append(
            BookingDetail(
                booking_id=b.id,
                service_name=b.service.name if b.service else "Service",
                caregiver_name=cg_name,
                date=b.booking_date,
                start_time=b.start_time.strftime("%H:%M"),
                end_time=b.end_time.strftime("%H:%M"),
                price_cents=b.price_cents
            )
        )
    return details

@router.patch("/{booking_id}/cancel", response_model=CancelResponse)
async def cancel_booking(
    booking_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Booking).where(Booking.id == booking_id))
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found.")
    
    if booking.status == "CANCELLED":
        return {
            "status": "already_cancelled",
            "message": "Booking was already cancelled.",
            "booking_id": booking.id
        }
    
    booking.status = "CANCELLED"
    await db.commit()
    return {
        "status": "cancelled",
        "message": "Booking has been successfully cancelled.",
        "booking_id": booking.id
    }
