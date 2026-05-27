from datetime import date, time, datetime, timedelta
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.service import Service
from models.user import User
from models.caregiver_service import CaregiverService
from models.booking import Booking
from schemas.slot import SlotResponse, SlotDetail, CaregiverRef

def generate_slots(
    target_date: date,
    duration_minutes: int,
    day_start: time = time(8, 0),
    day_end: time = time(20, 0),
) -> list[time]:
    """
    Generates all 15-min-aligned start times within working hours
    where a full service duration fits before day_end.
    """
    slots = []
    cursor = datetime.combine(target_date, day_start)
    end_boundary = datetime.combine(target_date, day_end)
    step = timedelta(minutes=15)
    service_duration = timedelta(minutes=duration_minutes)

    while cursor + service_duration <= end_boundary:
        slots.append(cursor.time())
        cursor += step
    return slots

async def get_available_slots(
    service_id: int,
    target_date: date,
    patient_id: int,
    db: AsyncSession
) -> SlotResponse:
    # 1. Fetch service details
    srv_result = await db.execute(select(Service).where(Service.id == service_id))
    service = srv_result.scalar_one_or_none()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    duration = service.duration_minutes

    # 2. Fetch qualified caregivers for this service
    cg_srv_result = await db.execute(
        select(User).join(
            CaregiverService, CaregiverService.caregiver_id == User.id
        ).where(
            CaregiverService.service_id == service_id,
            User.role == "CAREGIVER"
        )
    )
    qualified_caregivers = cg_srv_result.scalars().all()
    if not qualified_caregivers:
        return SlotResponse(
            service_id=service_id,
            date=target_date,
            duration_minutes=duration,
            available_slots=[]
        )

    qualified_caregiver_ids = [cg.id for cg in qualified_caregivers]
    qualified_cg_map = {cg.id: cg.name for cg in qualified_caregivers}

    # 3. Generate candidate start times
    candidate_start_times = generate_slots(target_date, duration)

    available_slots = []

    # 4. Filter candidate slots
    for start_time in candidate_start_times:
        # Compute end_time for candidate slot
        start_dt = datetime.combine(target_date, start_time)
        end_dt = start_dt + timedelta(minutes=duration)
        end_time = end_dt.time()

        # Query conflicting bookings for any of the qualified caregivers in this window
        # Overlap check: bookings.start_time < end_time AND bookings.end_time > start_time
        cg_conflict_result = await db.execute(
            select(Booking.caregiver_id).where(
                Booking.caregiver_id.in_(qualified_caregiver_ids),
                Booking.booking_date == target_date,
                Booking.status == "CONFIRMED",
                Booking.start_time < end_time,
                Booking.end_time > start_time
            )
        )
        busy_caregiver_ids = set(cg_conflict_result.scalars().all())
        free_caregivers = [
            CaregiverRef(id=cg_id, name=qualified_cg_map[cg_id])
            for cg_id in qualified_caregiver_ids
            if cg_id not in busy_caregiver_ids
        ]

        # If no caregiver is available, skip this slot
        if not free_caregivers:
            continue

        # Query conflicting bookings for patient in this window
        patient_conflict_result = await db.execute(
            select(Booking.id).where(
                Booking.patient_id == patient_id,
                Booking.booking_date == target_date,
                Booking.status == "CONFIRMED",
                Booking.start_time < end_time,
                Booking.end_time > start_time
            )
        )
        patient_has_conflict = patient_conflict_result.first() is not None

        # If patient has conflict, skip this slot
        if patient_has_conflict:
            continue

        # Slot is available!
        available_slots.append(
            SlotDetail(
                start_time=start_time.strftime("%H:%M"),
                end_time=end_time.strftime("%H:%M"),
                available_caregivers=free_caregivers
            )
        )

    return SlotResponse(
        service_id=service_id,
        date=target_date,
        duration_minutes=duration,
        available_slots=available_slots
    )
