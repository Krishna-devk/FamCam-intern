from sqlalchemy import Column, Integer, ForeignKey
from database import Base

class CaregiverService(Base):
    __tablename__ = "caregiver_services"

    caregiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="CASCADE"), primary_key=True)
