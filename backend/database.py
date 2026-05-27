import os
import urllib.parse as urlparse
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base

load_dotenv()

# Default fallback to sqlite+aiosqlite or standard postgresql for local testing if DATABASE_URL is not set
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@localhost:5432/famcare")

# Convert postgresql:// to postgresql+asyncpg:// if needed
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)

connect_args = {}

# Strip sslmode and channel_binding or other asyncpg incompatible parameters
if "?" in DATABASE_URL:
    parsed = urlparse.urlparse(DATABASE_URL)
    query = urlparse.parse_qs(parsed.query)
    
    # Check if sslmode is present
    sslmode = query.pop("sslmode", None)
    query.pop("channel_binding", None)  # Not supported by asyncpg connect() args
    
    # Rebuild query
    new_query = urlparse.urlencode(query, doseq=True)
    parsed = parsed._replace(query=new_query)
    DATABASE_URL = urlparse.urlunparse(parsed)
    
    # If sslmode was set or we are connecting to a cloud service like Neon, enforce ssl
    if sslmode or "neon.tech" in DATABASE_URL:
        connect_args["ssl"] = "require"

from sqlalchemy.pool import NullPool

engine = create_async_engine(
    DATABASE_URL,
    connect_args=connect_args,
    poolclass=NullPool,
    echo=False
)

async_session = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()

async def get_db():
    async with async_session() as session:
        yield session

