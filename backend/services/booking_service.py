from datetime import datetime, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.service import Service
from models.caregiver_service import CaregiverService
from models.booking import Booking
from schemas.checkout import CheckoutRequest, CheckoutSuccessResponse, BookingDetail
from exceptions import BookingConflictError

async def execute_checkout(
    request: CheckoutRequest,
    db: AsyncSession
) -> CheckoutSuccessResponse:
    if db.in_transaction():
        return await _execute_checkout_transactional(request, db)
    else:
        async with db.begin():
            return await _execute_checkout_transactional(request, db)

async def _execute_checkout_transactional(
    request: CheckoutRequest,
    db: AsyncSession
) -> CheckoutSuccessResponse:
    patient_id = request.patient_id
    items = request.items
    
    staged_bookings = []
    total_price_cents = 0
    
    patient_res = await db.execute(
        select(User).where(
            User.id == patient_id,
            User.role == "PATIENT",
        )
    )
    patient = patient_res.scalar_one_or_none()
    if not patient:
        raise BookingConflictError(
            index=0,
            reason_code="PATIENT_NOT_FOUND",
            message="Patient does not exist.",
            item={
                "service_id": items[0].service_id,
                "caregiver_id": items[0].caregiver_id,
                "date": items[0].date,
                "start_time": items[0].start_time,
            },
        )

    # We execute staged items inside the transaction session
    if True:
        # Keep track of local slots in this request to prevent self-overlap in cart
        booked_caregivers_in_request = {} # (cg_id, date) -> list of (start, end)
        booked_patient_in_request = {}     # date -> list of (start, end)

        for i, item in enumerate(items):
            item_dict = {
                "service_id": item.service_id,
                "caregiver_id": item.caregiver_id,
                "date": item.date,
                "start_time": item.start_time
            }
            date_str = item.date.isoformat()

            # Step 1: Service fetch (pessimistic lock)
            srv_stmt = select(Service).where(Service.id == item.service_id)
            if "sqlite" not in db.bind.dialect.name:
                srv_stmt = srv_stmt.with_for_update()
            service_result = await db.execute(srv_stmt)
            service = service_result.scalar_one_or_none()
            if not service:
                raise BookingConflictError(
                    index=i,
                    reason_code="SERVICE_NOT_FOUND",
                    message="Service does not exist.",
                    item=item_dict
                )

            duration = service.duration_minutes
            start_dt = datetime.combine(item.date, item.start_time)
            end_dt = start_dt + timedelta(minutes=duration)
            end_time = end_dt.time()

            caregiver_res = await db.execute(
                select(User).where(
                    User.id == item.caregiver_id,
                    User.role == "CAREGIVER",
                )
            )
            caregiver = caregiver_res.scalar_one_or_none()
            if not caregiver:
                raise BookingConflictError(
                    index=i,
                    reason_code="CAREGIVER_NOT_FOUND",
                    message="Caregiver does not exist.",
                    item=item_dict
                )

            # Step 2: Validate caregiver qualification
            qual_result = await db.execute(
                select(CaregiverService).where(
                    CaregiverService.caregiver_id == item.caregiver_id,
                    CaregiverService.service_id == item.service_id
                )
            )
            qualification = qual_result.scalar_one_or_none()
            if not qualification:
                raise BookingConflictError(
                    index=i,
                    reason_code="CAREGIVER_NOT_QUALIFIED",
                    message="Caregiver is not qualified for this service.",
                    item=item_dict
                )

            # Step 3: Alignment check is already handled by Pydantic field validator!
            # But let's verify it here as well just in case:
            if item.start_time.minute % 15 != 0:
                raise BookingConflictError(
                    index=i,
                    reason_code="SLOT_NOT_15_MIN_ALIGNED",
                    message="Slot start time is not 15-minute aligned.",
                    item=item_dict
                )

            # Step 4: Check caregiver overlap in current request (intra-payload)
            cg_key = (item.caregiver_id, item.date)
            if cg_key in booked_caregivers_in_request:
                for existing_start, existing_end in booked_caregivers_in_request[cg_key]:
                    if item.start_time < existing_end and end_time > existing_start:
                        cg_name_res = await db.execute(select(User.name).where(User.id == item.caregiver_id))
                        cg_name = cg_name_res.scalar() or "Caregiver"
                        raise BookingConflictError(
                            index=i,
                            reason_code="CAREGIVER_OVERLAP",
                            message=f"Caregiver {cg_name} is already booked from {existing_start.strftime('%H:%M')} to {existing_end.strftime('%H:%M')} on {date_str}.",
                            item=item_dict
                        )
            
            # Step 5: Lock + Check Caregiver overlap in DB
            cg_stmt = (
                select(Booking)
                .where(
                    Booking.caregiver_id == item.caregiver_id,
                    Booking.booking_date == item.date,
                    Booking.status == "CONFIRMED",
                    Booking.start_time < end_time,
                    Booking.end_time > item.start_time
                )
            )
            if "sqlite" not in db.bind.dialect.name:
                cg_stmt = cg_stmt.with_for_update()
            cg_conflict = await db.execute(cg_stmt)
            cg_booking_conflict = cg_conflict.first()
            if cg_booking_conflict is not None:
                cg_name_res = await db.execute(select(User.name).where(User.id == item.caregiver_id))
                cg_name = cg_name_res.scalar() or "Caregiver"
                # Find the actual conflict times from the DB record
                conflict_start = cg_booking_conflict[0].start_time.strftime("%H:%M")
                conflict_end = cg_booking_conflict[0].end_time.strftime("%H:%M")
                raise BookingConflictError(
                    index=i,
                    reason_code="CAREGIVER_OVERLAP",
                    message=f"Caregiver {cg_name} is already booked from {conflict_start} to {conflict_end} on {date_str}.",
                    item=item_dict
                )

            # Step 6: Check patient overlap in current request (intra-payload)
            p_key = item.date
            if p_key in booked_patient_in_request:
                for existing_start, existing_end in booked_patient_in_request[p_key]:
                    if item.start_time < existing_end and end_time > existing_start:
                        raise BookingConflictError(
                            index=i,
                            reason_code="PATIENT_OVERLAP",
                            message=f"Patient already has an overlapping service on {date_str}.",
                            item=item_dict
                        )

            # Lock + Check Patient overlap in DB
            p_stmt = (
                select(Booking)
                .where(
                    Booking.patient_id == patient_id,
                    Booking.booking_date == item.date,
                    Booking.status == "CONFIRMED",
                    Booking.start_time < end_time,
                    Booking.end_time > item.start_time
                )
            )
            if "sqlite" not in db.bind.dialect.name:
                p_stmt = p_stmt.with_for_update()
            patient_conflict = await db.execute(p_stmt)
            if patient_conflict.first() is not None:
                raise BookingConflictError(
                    index=i,
                    reason_code="PATIENT_OVERLAP",
                    message=f"Patient already has an overlapping service on {date_str}.",
                    item=item_dict
                )

            # Qualified! Record conflict metadata in-memory for intra-payload safety
            booked_caregivers_in_request.setdefault(cg_key, []).append((item.start_time, end_time))
            booked_patient_in_request.setdefault(p_key, []).append((item.start_time, end_time))

            # Step 7: Stage INSERT
            new_booking = Booking(
                patient_id=patient_id,
                caregiver_id=item.caregiver_id,
                service_id=item.service_id,
                booking_date=item.date,
                start_time=item.start_time,
                end_time=end_time,
                price_cents=service.price_cents,
                status="CONFIRMED"
            )
            db.add(new_booking)
            staged_bookings.append((new_booking, service.name))
            total_price_cents += service.price_cents
            
            # Flush session to register inserts and ensure subsequent checks inside transaction see them
            await db.flush()

    # The transaction block auto-commits upon exit. Now we can compile response details.
    booking_ids = [b[0].id for b in staged_bookings]
    details = []
    
    for booking, service_name in staged_bookings:
        # Get caregiver name for receipt
        cg_res = await db.execute(select(User.name).where(User.id == booking.caregiver_id))
        cg_name = cg_res.scalar() or "Caregiver"
        
        details.append(
            BookingDetail(
                booking_id=booking.id,
                service_name=service_name,
                caregiver_name=cg_name,
                date=booking.booking_date,
                start_time=booking.start_time.strftime("%H:%M"),
                end_time=booking.end_time.strftime("%H:%M"),
                price_cents=booking.price_cents
            )
        )

    return CheckoutSuccessResponse(
        status="confirmed",
        booking_ids=booking_ids,
        total_price_cents=total_price_cents,
        items=details
    )
