import pytest
from datetime import date, time
from sqlalchemy import select
from models.booking import Booking

pytestmark = pytest.mark.asyncio

async def test_single_item_checkout_success(async_client, db_session):
    payload = {
        "patient_id": 1,
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
    assert response.status_code == 201, response.text
    
    data = response.json()
    assert data["status"] == "confirmed"
    assert len(data["booking_ids"]) == 1
    assert data["total_price_cents"] == 8000
    assert len(data["items"]) == 1
    
    item = data["items"][0]
    assert item["booking_id"] == data["booking_ids"][0]
    assert item["service_name"] == "Physiotherapy"
    assert item["caregiver_name"] == "Priya Sharma"
    assert item["date"] == "2025-08-15"
    assert item["start_time"] == "09:00"
    assert item["end_time"] == "10:00" # 60 mins duration
    assert item["price_cents"] == 8000

async def test_multi_item_checkout_success(async_client, db_session):
    # Caregiver 4 (Rahul) is not qualified for Wound Dressing (service 2).
    # Priya (3), Kavita (5), and Deepak (6) are qualified. We use Kavita (5).
    payload = {
        "patient_id": 1,
        "items": [
            {
                "service_id": 1,
                "caregiver_id": 3,
                "date": "2025-08-15",
                "start_time": "09:00"
            },
            {
                "service_id": 2,
                "caregiver_id": 5,
                "date": "2025-08-16",
                "start_time": "10:30"
            }
        ]
    }
    
    response = await async_client.post("/cart/checkout", json=payload)
    assert response.status_code == 201, response.text
    
    data = response.json()
    assert data["status"] == "confirmed"
    assert len(data["booking_ids"]) == 2
    assert data["total_price_cents"] == 12000 # 8000 + 4000
    assert len(data["items"]) == 2
    
    # Verify both items were stored
    stmt = select(Booking).where(Booking.id.in_(data["booking_ids"]))
    bookings_res = await db_session.execute(stmt)
    bookings = bookings_res.scalars().all()
    assert len(bookings) == 2

async def test_available_slots_excludes_booked(async_client, db_session):
    # Book caregiver 3 on 2025-08-15 from 10:00 to 11:00 (Physiotherapy)
    booking = Booking(
        patient_id=1,
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

    # Query available slots for service 1 (Physiotherapy, 60 mins duration) on 2025-08-15
    # Caregivers qualified: 3 (Priya), 4 (Rahul), 6 (Deepak)
    # Let's also book caregivers 4 and 6 at 10:00 to make the slot fully unavailable
    booking4 = Booking(
        patient_id=2,
        caregiver_id=4,
        service_id=1,
        booking_date=date(2025, 8, 15),
        start_time=time(10, 0),
        end_time=time(11, 0),
        price_cents=8000,
        status="CONFIRMED"
    )
    booking6 = Booking(
        patient_id=2,
        caregiver_id=6,
        service_id=1,
        booking_date=date(2025, 8, 15),
        start_time=time(10, 0),
        end_time=time(11, 0),
        price_cents=8000,
        status="CONFIRMED"
    )
    db_session.add(booking4)
    db_session.add(booking6)
    await db_session.commit()

    response = await async_client.get("/slots/available?service_id=1&date=2025-08-15&patient_id=1")
    assert response.status_code == 200
    
    data = response.json()
    slots = data["available_slots"]
    
    # 10:00 slot (and overlapping 09:15, 09:30, 09:45, 10:15, 10:30, 10:45) must not have ANY available caregivers
    # So they should either be completely excluded from the slots list, or have empty caregiver list
    # If the logic filters out slots with 0 available caregivers, they won't even appear in available_slots
    start_times = [s["start_time"] for s in slots]
    
    # Assert 10:00 starts are completely excluded
    assert "10:00" not in start_times
    # 09:00 should be present since it ends at 10:00, which has no overlap with 10:00 start (they touch at the boundary, which is allowed)
    assert "09:00" in start_times
