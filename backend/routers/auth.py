from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models.user import User
from schemas.extra import LoginRequest, UserResponse, RegisterRequest

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=UserResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found with this email.")
    
    # If the user has a password set in DB, verify it
    if user.password is not None and user.password != payload.password:
        raise HTTPException(status_code=401, detail="Incorrect password.")
        
    return user

@router.post("/register", response_model=UserResponse, status_code=201)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="A user with this email already exists.")
    
    new_user = User(
        name=payload.name,
        email=payload.email,
        role=payload.role,
        password=payload.password
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user
