import asyncio
import pytest
import os
import sys
from dotenv import load_dotenv

# Ensure backend root directory is in sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from httpx import AsyncClient, ASGITransport

# Load env before imports
load_dotenv()

import socket

# We point tests to famcare_test database
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@localhost:5432/famcare_test"
)

# Dynamic self-healing detector checking local PostgreSQL availability on port 5432
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.5)
    s.connect(("localhost", 5432))
    s.close()
    engine_url = TEST_DATABASE_URL
    print("PostgreSQL server detected on port 5432. Running tests on PostgreSQL.")
except Exception:
    engine_url = "sqlite+aiosqlite:///test_famcare.db"
    print("PostgreSQL not active. Falling back seamlessly to SQLite file-based database for tests.")

# Create the test engine
test_engine = create_async_engine(engine_url, echo=False)
test_sessionmaker = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

from sqlalchemy import event

@event.listens_for(test_engine.sync_engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    if "sqlite" in test_engine.dialect.name:
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA busy_timeout=5000")
        cursor.close()

@event.listens_for(test_engine.sync_engine, "begin")
def do_begin(conn):
    if "sqlite" in conn.dialect.name:
        conn.exec_driver_sql("BEGIN IMMEDIATE")

from main import app
from database import Base, get_db
from models.user import User
from models.service import Service
from models.caregiver_service import CaregiverService
from models.booking import Booking

import pytest_asyncio

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    # Setup tables on the test database before every test for perfect isolation
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest_asyncio.fixture
async def db_session():
    # Fresh session for each test committing changes that are subsequently cleared by setup_db
    async with test_sessionmaker() as session:
        yield session
        # Check if session is active before committing
        if session.is_active:
            await session.commit()

@pytest_asyncio.fixture(autouse=True)
async def override_get_db():
    async def _get_db():
        async with test_sessionmaker() as session:
            yield session
    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides.pop(get_db, None)

@pytest_asyncio.fixture
async def async_client():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as client:
        yield client

@pytest_asyncio.fixture(autouse=True)
async def seed_test_data(setup_db, db_session):
    # Insert services
    services_list = [
        Service(id=1, name="Physiotherapy", duration_minutes=60, price_cents=8000),
        Service(id=2, name="Wound Dressing", duration_minutes=30, price_cents=4000),
        Service(id=3, name="Medication Review", duration_minutes=45, price_cents=5500)
    ]
    for s in services_list:
        db_session.add(s)

    # Insert users
    users_list = [
        User(id=1, name="Arjun Mehta", email="arjun@famcare.in", role="PATIENT"),
        User(id=2, name="Sunita Rao", email="sunita@famcare.in", role="PATIENT"),
        User(id=3, name="Priya Sharma", email="priya@famcare.in", role="CAREGIVER"),
        User(id=4, name="Rahul Verma", email="rahul@famcare.in", role="CAREGIVER"),
        User(id=5, name="Kavita Singh", email="kavita@famcare.in", role="CAREGIVER"),
        User(id=6, name="Deepak Nair", email="deepak@famcare.in", role="CAREGIVER")
    ]
    for u in users_list:
        db_session.add(u)

    await db_session.commit()

    # Insert qualifications (caregiver_services)
    qualifications = [
        CaregiverService(caregiver_id=3, service_id=1), # Priya -> Physio
        CaregiverService(caregiver_id=3, service_id=2), # Priya -> Wound
        CaregiverService(caregiver_id=4, service_id=1), # Rahul -> Physio
        CaregiverService(caregiver_id=4, service_id=3), # Rahul -> Meds
        CaregiverService(caregiver_id=5, service_id=2), # Kavita -> Wound
        CaregiverService(caregiver_id=5, service_id=3), # Kavita -> Meds
        CaregiverService(caregiver_id=6, service_id=1), # Deepak -> Physio
        CaregiverService(caregiver_id=6, service_id=2), # Deepak -> Wound
        CaregiverService(caregiver_id=6, service_id=3)  # Deepak -> Meds
    ]
    for cs in qualifications:
        db_session.add(cs)

    await db_session.commit()
