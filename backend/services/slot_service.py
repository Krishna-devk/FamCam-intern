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

    # 3. Fetch ALL bookings for qualified caregivers and the patient on the target date
    all_cg_bookings_result = await db.execute(
        select(Booking.caregiver_id, Booking.start_time, Booking.end_time).where(
            Booking.caregiver_id.in_(qualified_caregiver_ids),
            Booking.booking_date == target_date,
            Booking.status == "CONFIRMED"
        )
    )
    cg_bookings = all_cg_bookings_result.all()

    all_patient_bookings_result = await db.execute(
        select(Booking.start_time, Booking.end_time).where(
            Booking.patient_id == patient_id,
            Booking.booking_date == target_date,
            Booking.status == "CONFIRMED"
        )
    )
    patient_bookings = all_patient_bookings_result.all()

    # 4. Generate candidate start times
    candidate_start_times = generate_slots(target_date, duration)

    available_slots = []

    # 5. Filter candidate slots in memory
    for start_time in candidate_start_times:
        # Compute end_time for candidate slot
        start_dt = datetime.combine(target_date, start_time)
        end_dt = start_dt + timedelta(minutes=duration)
        end_time = end_dt.time()

        # Check patient conflicts in memory
        patient_has_conflict = any(
            pb.start_time < end_time and pb.end_time > start_time 
            for pb in patient_bookings
        )
        # If patient has conflict, skip this slot
        if patient_has_conflict:
            continue

        # Check caregiver conflicts in memory
        busy_caregiver_ids = {
            cb.caregiver_id for cb in cg_bookings
            if cb.start_time < end_time and cb.end_time > start_time
        }

        free_caregivers = [
            CaregiverRef(id=cg_id, name=qualified_cg_map[cg_id])
            for cg_id in qualified_caregiver_ids
            if cg_id not in busy_caregiver_ids
        ]

        # If no caregiver is available, skip this slot
        if not free_caregivers:
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
