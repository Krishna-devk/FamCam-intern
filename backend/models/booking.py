from sqlalchemy import Column, Integer, String, Date, Time, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from database import Base

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    caregiver_id = Column(Integer, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="RESTRICT"), nullable=False)
    booking_date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False) # Stored, not computed
    price_cents = Column(Integer, nullable=False)
    status = Column(String(20), nullable=False, default="CONFIRMED") # 'CONFIRMED' or 'CANCELLED'
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    patient = relationship("User", foreign_keys=[patient_id], backref="patient_bookings")
    caregiver = relationship("User", foreign_keys=[caregiver_id], backref="caregiver_bookings")
    service = relationship("Service", backref="bookings")
