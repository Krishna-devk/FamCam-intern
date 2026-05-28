from pydantic import BaseModel, Field

class FamilyMemberBase(BaseModel):
    name: str = Field(..., max_length=100)
    relation: str = Field(..., max_length=50)
    initials: str = Field(..., max_length=10)

class FamilyMemberCreate(FamilyMemberBase):
    pass

class FamilyMemberResponse(FamilyMemberBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
