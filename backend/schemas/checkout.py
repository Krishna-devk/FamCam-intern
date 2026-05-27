from pydantic import BaseModel, Field, field_validator
from datetime import date, time
from typing import List, Literal, Optional, Dict, Any

class CheckoutItem(BaseModel):
    service_id: int
    caregiver_id: int
    date: date
    start_time: time

    @field_validator("start_time")
    @classmethod
    def check_alignment(cls, v: time) -> time:
        if v.minute % 15 != 0:
            raise ValueError("SLOT_NOT_15_MIN_ALIGNED")
        return v

class CheckoutRequest(BaseModel):
    patient_id: int
    items: List[CheckoutItem] = Field(..., min_length=1)

class BookingDetail(BaseModel):
    booking_id: int
    service_name: str
    caregiver_name: str
    date: date
    start_time: str
    end_time: str
    price_cents: int

class CheckoutSuccessResponse(BaseModel):
    status: Literal["confirmed"] = "confirmed"
    booking_ids: List[int]
    total_price_cents: int
    items: List[BookingDetail]

class FailedItemDetail(BaseModel):
    service_id: int
    caregiver_id: int
    date: date
    start_time: str

class CheckoutFailureResponse(BaseModel):
    status: Literal["failed"] = "failed"
    failed_item_index: int
    failed_item: FailedItemDetail
    reason_code: str
    message: str
