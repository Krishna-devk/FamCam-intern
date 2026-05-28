import asyncio
from database import engine, Base
import models  # to ensure all models are registered

async def init_db():
    async with engine.begin() as conn:
        # This will create tables that don't exist yet, without dropping them
        await conn.run_sync(Base.metadata.create_all)
        print("Created missing tables.")

if __name__ == "__main__":
    asyncio.run(init_db())
