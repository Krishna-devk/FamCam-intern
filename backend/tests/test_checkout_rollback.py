import pytest
from datetime import date, time
from sqlalchemy import select
from models.booking import Booking

pytestmark = pytest.mark.asyncio

async def test_rollback_on_caregiver_conflict(async_client, db_session):
    # Book caregiver 3 on 2025-08-15 from 10:00 to 11:00
    booking = Booking(
        patient_id=2,
        caregiver_id=3,
        service_id=1,
        booking_date=date(2025, 8, 15),
        start_time=time(10, 0),
        end_time=time(11, 0),
        price_cents=8000,
        status="CONFIRMED"
    )
    db_session.add(booking)
    await db_session.commit()

    # Payload with valid item at index 0, and conflicting item for caregiver 3 at index 1
    payload = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 2, # Wound Dressing (30 min)
                "caregiver_id": 5, # Kavita
                "date": "2025-08-15",
                "start_time": "09:00" # ends 09:30, completely valid
            },
            {
                "service_id": 1, # Physiotherapy (60 min)
                "caregiver_id": 3, # Priya (already booked 10:00 - 11:00)
                "date": "2025-08-15",
                "start_time": "10:30" # Overlaps from 10:30 to 11:30!
            }
        ]
    }

    response = await async_client.post("/cart/checkout", json=payload)
    assert response.status_code == 400
    
    data = response.json()
    assert data["status"] == "failed"
    assert data["failed_item_index"] == 1
    assert data["reason_code"] == "CAREGIVER_OVERLAP"
    assert "Priya Sharma" in data["message"]
    
    # Confirm that absolutely ZERO new bookings were created in the database (total bookings count is still exactly 1)
    stmt = select(Booking)
    bookings_res = await db_session.execute(stmt)
    bookings = bookings_res.scalars().all()
    assert len(bookings) == 1
    assert bookings[0].patient_id == 2 # Only the pre-existing booking exists

async def test_rollback_on_patient_conflict(async_client, db_session):
    # Book patient 1 on 2025-08-15 from 09:00 to 09:30
    booking = Booking(
        patient_id=1,
        caregiver_id=5,
        service_id=2,
        booking_date=date(2025, 8, 15),
        start_time=time(9, 0),
        end_time=time(9, 30),
        price_cents=4000,
        status="CONFIRMED"
    )
    db_session.add(booking)
    await db_session.commit()

    payload = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 3, # Med Review (45 min)
                "caregiver_id": 5, # Kavita
                "date": "2025-08-15",
                "start_time": "11:00" # Valid
            },
            {
                "service_id": 1, # Physio (60 min)
                "caregiver_id": 3, # Priya
                "date": "2025-08-15",
                "start_time": "09:15" # Conflicts with patient's pre-existing 09:00-09:30 slot!
            }
        ]
    }

    response = await async_client.post("/cart/checkout", json=payload)
    assert response.status_code == 400
    
    data = response.json()
    assert data["status"] == "failed"
    assert data["failed_item_index"] == 1
    assert data["reason_code"] == "PATIENT_OVERLAP"
    
    # Confirm that absolutely ZERO new bookings were committed
    stmt = select(Booking)
    bookings_res = await db_session.execute(stmt)
    bookings = bookings_res.scalars().all()
    assert len(bookings) == 1
    assert bookings[0].start_time == time(9, 0)

async def test_rollback_on_invalid_service(async_client, db_session):
    payload = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 1,
                "caregiver_id": 3,
                "date": "2025-08-15",
                "start_time": "09:00" # Valid
            },
            {
                "service_id": 9999, # Non-existent service ID!
                "caregiver_id": 4,
                "date": "2025-08-15",
                "start_time": "10:30"
            }
        ]
    }

    response = await async_client.post("/cart/checkout", json=payload)
    assert response.status_code == 400
    
    data = response.json()
    print("Rollback test actual response data:", data)
    assert data["status"] == "failed"
    assert data["failed_item_index"] == 1
    assert data["reason_code"] == "SERVICE_NOT_FOUND"
    
    # Confirm 0 bookings in database
    stmt = select(Booking)
    bookings_res = await db_session.execute(stmt)
    bookings = bookings_res.scalars().all()
    assert len(bookings) == 0

async def test_fails_when_patient_not_found(async_client, db_session):
    payload = {
        "patient_id": 9999,
        "items": [
            {
                "service_id": 1,
                "caregiver_id": 3,
                "date": "2025-08-15",
                "start_time": "09:00"
            }
        ]
    }

    response = await async_client.post("/cart/checkout", json=payload)
    assert response.status_code == 400
    data = response.json()
    assert data["status"] == "failed"
    assert data["reason_code"] == "PATIENT_NOT_FOUND"

async def test_fails_when_caregiver_not_found(async_client, db_session):
    payload = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 1,
                "caregiver_id": 9999,
                "date": "2025-08-15",
                "start_time": "09:00"
            }
        ]
    }

    response = await async_client.post("/cart/checkout", json=payload)
    assert response.status_code == 400
    data = response.json()
    assert data["status"] == "failed"
    assert data["reason_code"] == "CAREGIVER_NOT_FOUND"
