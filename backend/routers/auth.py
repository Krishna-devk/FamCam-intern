from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, delete, or_
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models.user import User
from models import Booking, FamilyMember, CaregiverService
from schemas.extra import LoginRequest, UserResponse, RegisterRequest, UserUpdateRequest, PasswordChangeRequest

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

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: int, payload: UserUpdateRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    # Check if email is being updated and already exists
    if user.email != payload.email:
        email_check = await db.execute(select(User).where(User.email == payload.email))
        if email_check.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Email already in use.")

    user.name = payload.name
    user.email = payload.email
    await db.commit()
    await db.refresh(user)
    return user

@router.put("/{user_id}/password")
async def change_password(user_id: int, payload: PasswordChangeRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    if user.password is not None and user.password != payload.current_password:
        raise HTTPException(status_code=401, detail="Incorrect current password.")
    
    user.password = payload.new_password
    await db.commit()
    return {"status": "success", "message": "Password updated successfully."}

@router.delete("/{user_id}")
async def delete_user(user_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    # Manually delete dependent records to avoid IntegrityError (Foreign Key violations)
    await db.execute(delete(Booking).where(or_(Booking.patient_id == user_id, Booking.caregiver_id == user_id)))
    await db.execute(delete(FamilyMember).where(FamilyMember.user_id == user_id))
    await db.execute(delete(CaregiverService).where(CaregiverService.caregiver_id == user_id))
    
    await db.delete(user)
    await db.commit()
    return {"status": "success", "message": "Account deleted successfully."}
