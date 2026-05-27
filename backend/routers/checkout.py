from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from schemas.checkout import CheckoutRequest, CheckoutSuccessResponse
from services.booking_service import execute_checkout

router = APIRouter()

@router.post("/cart/checkout", response_model=CheckoutSuccessResponse, status_code=201)
async def checkout(
    payload: CheckoutRequest,
    db: AsyncSession = Depends(get_db)
):
    return await execute_checkout(request=payload, db=db)
