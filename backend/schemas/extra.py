from pydantic import BaseModel, Field
from typing import List, Literal, Optional

class FAQItem(BaseModel):
    id: int
    question: str
    answer: str

class FAQListResponse(BaseModel):
    faqs: List[FAQItem]

class LoginRequest(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str

class CancelResponse(BaseModel):
    status: str
    message: str
    booking_id: int

class RegisterRequest(BaseModel):
    name: str = Field(..., max_length=100)
    email: str = Field(..., max_length=255)
    role: Literal['PATIENT', 'CAREGIVER']
    password: str = Field(..., min_length=4)

class UserUpdateRequest(BaseModel):
    name: str = Field(..., max_length=100)
    email: str = Field(..., max_length=255)

class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=4)
