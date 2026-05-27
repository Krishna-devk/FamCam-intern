from sqlalchemy import Column, Integer, String, Text, DateTime, func
from database import Base

class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    duration_minutes = Column(Integer, nullable=False) # Must be % 15 == 0 in DDL
    price_cents = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
