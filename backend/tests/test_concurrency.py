import pytest
import asyncio
from datetime import date, time
from sqlalchemy import select
from models.booking import Booking

pytestmark = pytest.mark.asyncio

async def test_concurrent_checkout_no_double_booking(async_client, db_session):
    # Two simultaneous requests trying to book caregiver 3 for Physiotherapy at 10:00 on 2025-08-15
    payload_a = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 1,
                "caregiver_id": 3,
                "date": "2025-08-15",
                "start_time": "10:00"
            }
        ]
    }
    
    payload_b = {
        "patient_id": 2,
        "items": [
            {
                "service_id": 1,
                "caregiver_id": 3,
                "date": "2025-08-15",
                "start_time": "10:00"
            }
        ]
    }

    # Fire both checkout requests concurrently
    res_a, res_b = await asyncio.gather(
        async_client.post("/cart/checkout", json=payload_a),
        async_client.post("/cart/checkout", json=payload_b),
        return_exceptions=True
    )

    # Gather status codes
    status_codes = [res_a.status_code, res_b.status_code]
    assert 201 in status_codes
    assert 400 in status_codes

    # Exactly one succeeded and one failed
    success_res = res_a if res_a.status_code == 201 else res_b
    fail_res = res_a if res_a.status_code == 400 else res_b

    # Verify structured failure reason
    fail_data = fail_res.json()
    assert fail_data["status"] == "failed"
    assert fail_data["reason_code"] == "CAREGIVER_OVERLAP"
    assert "Priya Sharma" in fail_data["message"]

    # Verify database contains exactly ONE active booking
    stmt = select(Booking)
    bookings_res = await db_session.execute(stmt)
    bookings = bookings_res.scalars().all()
    assert len(bookings) == 1
    assert bookings[0].caregiver_id == 3
    assert bookings[0].start_time == time(10, 0)

async def test_concurrent_patient_self_conflict(async_client, db_session):
    # Two simultaneous requests trying to book overlapping slots for the same patient
    payload_a = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 2, # Wound Dressing (30 min) -> 09:00 - 09:30
                "caregiver_id": 3, # Priya
                "date": "2025-08-15",
                "start_time": "09:00"
            }
        ]
    }
    
    payload_b = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 1, # Physiotherapy (60 min) -> 09:15 - 10:15 (overlaps!)
                "caregiver_id": 6, # Deepak
                "date": "2025-08-15",
                "start_time": "09:15"
            }
        ]
    }

    res_a, res_b = await asyncio.gather(
        async_client.post("/cart/checkout", json=payload_a),
        async_client.post("/cart/checkout", json=payload_b),
        return_exceptions=True
    )

    status_codes = [res_a.status_code, res_b.status_code]
    assert 201 in status_codes
    assert 400 in status_codes

    fail_res = res_a if res_a.status_code == 400 else res_b
    fail_data = fail_res.json()
    assert fail_data["status"] == "failed"
    assert fail_data["reason_code"] == "PATIENT_OVERLAP"

    # Exactly one booking committed
    stmt = select(Booking)
    bookings_res = await db_session.execute(stmt)
    bookings = bookings_res.scalars().all()
    assert len(bookings) == 1
