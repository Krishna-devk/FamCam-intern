from fastapi import Request
from fastapi.responses import JSONResponse
from typing import Literal

class BookingConflictError(Exception):
    def __init__(
        self,
        index: int,
        reason_code: Literal[
            "CAREGIVER_OVERLAP",
            "PATIENT_OVERLAP",
            "SERVICE_NOT_FOUND",
            "CAREGIVER_NOT_QUALIFIED",
            "SLOT_NOT_15_MIN_ALIGNED",
            "PATIENT_NOT_FOUND",
            "CAREGIVER_NOT_FOUND",
        ],
        message: str,
        item: dict
    ):
        self.index = index
        self.reason_code = reason_code
        self.message = message
        self.item = item
        super().__init__(message)

async def booking_conflict_exception_handler(request: Request, exc: BookingConflictError):
    # Formats the failed_item datetime structures into strings for clean JSON serialization
    failed_item = exc.item.copy()
    if hasattr(failed_item.get("date"), "isoformat"):
        failed_item["date"] = failed_item["date"].isoformat()
    if hasattr(failed_item.get("start_time"), "strftime"):
        failed_item["start_time"] = failed_item["start_time"].strftime("%H:%M")

    return JSONResponse(
        status_code=400,
        content={
            "status": "failed",
            "failed_item_index": exc.index,
            "failed_item": failed_item,
            "reason_code": exc.reason_code,
            "message": exc.message,
        }
    )
