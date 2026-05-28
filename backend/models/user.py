from sqlalchemy import Column, Integer, String, DateTime, func
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    role = Column(String(20), nullable=False) # 'PATIENT' or 'CAREGIVER'
    password = Column(String(255), nullable=True) # Nullable to support existing seeded caregivers
    created_at = Column(DateTime(timezone=True), server_default=func.now())
