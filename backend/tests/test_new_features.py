import pytest

pytestmark = pytest.mark.asyncio

async def test_auth_login_success(async_client):
    payload = {"email": "arjun@famcare.in", "password": "any"}
    response = await async_client.post("/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "arjun@famcare.in"
    assert data["role"] == "PATIENT"
    assert data["name"] == "Arjun Mehta"

async def test_auth_login_fail(async_client):
    payload = {"email": "nonexistent@famcare.in", "password": "any"}
    response = await async_client.post("/auth/login", json=payload)
    assert response.status_code == 404

async def test_faq_list(async_client):
    response = await async_client.get("/faqs")
    assert response.status_code == 200
    data = response.json()
    assert "faqs" in data
    assert len(data["faqs"]) == 4
    assert data["faqs"][0]["question"] == "How are caregiver qualifications verified?"

async def test_bookings_history_and_cancellation(async_client):
    # Book single service first
    booking_payload = {
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
    checkout_res = await async_client.post("/cart/checkout", json=booking_payload)
    assert checkout_res.status_code == 201
    booking_id = checkout_res.json()["booking_ids"][0]

    # Get history
    history_res = await async_client.get("/bookings?patient_id=1")
    assert history_res.status_code == 200
    history_data = history_res.json()
    assert len(history_data) == 1
    assert history_data[0]["booking_id"] == booking_id
    assert history_data[0]["service_name"] == "Physiotherapy"

    # Cancel booking
    cancel_res = await async_client.patch(f"/bookings/{booking_id}/cancel")
    assert cancel_res.status_code == 200
    cancel_data = cancel_res.json()
    assert cancel_data["status"] == "cancelled"
    assert cancel_data["booking_id"] == booking_id
