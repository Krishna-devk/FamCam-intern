from pydantic import BaseModel, ConfigDict
from typing import Optional

class ServiceResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    duration_minutes: int
    price_cents: int
    image_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
