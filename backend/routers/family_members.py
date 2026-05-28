from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from database import get_db
from models.family_member import FamilyMember
from schemas.family_member import FamilyMemberCreate, FamilyMemberResponse

router = APIRouter(prefix="/family-members", tags=["Family Members"])

@router.get("", response_model=List[FamilyMemberResponse])
async def get_family_members(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(FamilyMember).where(FamilyMember.user_id == user_id))
    members = result.scalars().all()
    return members

@router.post("", response_model=FamilyMemberResponse, status_code=status.HTTP_201_CREATED)
async def create_family_member(
    user_id: int,
    member: FamilyMemberCreate,
    db: AsyncSession = Depends(get_db)
):
    new_member = FamilyMember(
        user_id=user_id,
        name=member.name,
        relation=member.relation,
        initials=member.initials
    )
    db.add(new_member)
    await db.commit()
    await db.refresh(new_member)
    return new_member

@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_family_member(
    member_id: int,
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(FamilyMember).where(FamilyMember.id == member_id, FamilyMember.user_id == user_id))
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=404, detail="Family member not found")
    
    await db.delete(member)
    await db.commit()
    return
