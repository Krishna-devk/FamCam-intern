import asyncio
from sqlalchemy import select
from database import engine, async_session, Base
from models.user import User
from models.service import Service
from models.caregiver_service import CaregiverService

SERVICES = [
    {"name": "Physiotherapy",     "duration_minutes": 60, "price_cents": 8000, "description": "Physical therapy service", "image_url": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=400&q=80"},
    {"name": "Wound Dressing",    "duration_minutes": 30, "price_cents": 4000, "description": "Dressing and cleaning of wounds", "image_url": "https://images.unsplash.com/photo-1603398938378-e54eab446dde?auto=format&fit=crop&w=400&q=80"},
    {"name": "Medication Review", "duration_minutes": 45, "price_cents": 5500, "description": "Reviewing medication schedule", "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80"},
    {"name": "Elderly Companion Care", "duration_minutes": 90, "price_cents": 6000, "description": "Social and companion care for elders", "image_url": "https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?auto=format&fit=crop&w=400&q=80"},
    {"name": "Occupational Therapy", "duration_minutes": 60, "price_cents": 8500, "description": "Daily activity coordination therapy", "image_url": "https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=400&q=80"},
    {"name": "Post-Surgical Nursing", "duration_minutes": 120, "price_cents": 12000, "description": "High-care post-surgical support", "image_url": "https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=400&q=80"},
    {"name": "Dietary & Nutrition Consult", "duration_minutes": 45, "price_cents": 5000, "description": "Personalized meal and diet plans", "image_url": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=400&q=80"},
    {"name": "Vital Signs Monitoring", "duration_minutes": 15, "price_cents": 2000, "description": "Regular blood pressure, sugar and pulse check", "image_url": "https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=400&q=80"},
]

USERS = [
    # Patients
    {"name": "Arjun Mehta",   "email": "arjun@famcare.in",  "role": "PATIENT"},
    {"name": "Sunita Rao",    "email": "sunita@famcare.in", "role": "PATIENT"},
    
    # Caregivers (22 total)
    {"name": "Priya Sharma",  "email": "priya@famcare.in",  "role": "CAREGIVER"},
    {"name": "Rahul Verma",   "email": "rahul@famcare.in",  "role": "CAREGIVER"},
    {"name": "Kavita Singh",  "email": "kavita@famcare.in", "role": "CAREGIVER"},
    {"name": "Deepak Nair",   "email": "deepak@famcare.in", "role": "CAREGIVER"},
    {"name": "Anjali Desai",  "email": "anjali@famcare.in",  "role": "CAREGIVER"},
    {"name": "Amit Patel",    "email": "amit@famcare.in",    "role": "CAREGIVER"},
    {"name": "Sneha Reddy",   "email": "sneha@famcare.in",   "role": "CAREGIVER"},
    {"name": "Vikram Joshi",  "email": "vikram@famcare.in",  "role": "CAREGIVER"},
    {"name": "Neha Malhotra", "email": "neha@famcare.in",   "role": "CAREGIVER"},
    {"name": "Rohan Das",     "email": "rohan@famcare.in",   "role": "CAREGIVER"},
    {"name": "Pooja Kapoor",  "email": "pooja@famcare.in",   "role": "CAREGIVER"},
    {"name": "Manish Gupta",  "email": "manish@famcare.in",  "role": "CAREGIVER"},
    {"name": "Divya Rao",     "email": "divya@famcare.in",   "role": "CAREGIVER"},
    {"name": "Sandeep Mishra","email": "sandeep@famcare.in", "role": "CAREGIVER"},
    {"name": "Ritu Saxena",   "email": "ritu@famcare.in",    "role": "CAREGIVER"},
    {"name": "Harish Choudhary", "email": "harish@famcare.in", "role": "CAREGIVER"},
    {"name": "Sunita Krishnan", "email": "sunitak@famcare.in", "role": "CAREGIVER"},
    {"name": "Rajesh Nair",   "email": "rajesh@famcare.in",  "role": "CAREGIVER"},
    {"name": "Meera Sen",     "email": "meera@famcare.in",   "role": "CAREGIVER"},
    {"name": "Sanjay Dutt",   "email": "sanjay@famcare.in",  "role": "CAREGIVER"},
    {"name": "Kiran Bedi",    "email": "kiran@famcare.in",   "role": "CAREGIVER"},
    {"name": "Alok Nath",     "email": "alok@famcare.in",    "role": "CAREGIVER"},
]

CAREGIVER_SERVICES = [
    # Priya: Physiotherapy + Wound Dressing
    ("priya@famcare.in", "Physiotherapy"),
    ("priya@famcare.in", "Wound Dressing"),
    
    # Rahul: Physiotherapy + Medication Review
    ("rahul@famcare.in", "Physiotherapy"),
    ("rahul@famcare.in", "Medication Review"),
    
    # Kavita: Wound Dressing + Medication Review
    ("kavita@famcare.in", "Wound Dressing"),
    ("kavita@famcare.in", "Medication Review"),
    
    # Deepak: All 8 services
    ("deepak@famcare.in", "Physiotherapy"),
    ("deepak@famcare.in", "Wound Dressing"),
    ("deepak@famcare.in", "Medication Review"),
    ("deepak@famcare.in", "Elderly Companion Care"),
    ("deepak@famcare.in", "Occupational Therapy"),
    ("deepak@famcare.in", "Post-Surgical Nursing"),
    ("deepak@famcare.in", "Dietary & Nutrition Consult"),
    ("deepak@famcare.in", "Vital Signs Monitoring"),

    # Anjali, Amit, Sneha: Elderly Companion Care + Occupational Therapy
    ("anjali@famcare.in", "Elderly Companion Care"),
    ("anjali@famcare.in", "Occupational Therapy"),
    ("amit@famcare.in", "Elderly Companion Care"),
    ("amit@famcare.in", "Occupational Therapy"),
    ("sneha@famcare.in", "Elderly Companion Care"),
    ("sneha@famcare.in", "Occupational Therapy"),

    # Vikram, Neha, Rohan: Post-Surgical Nursing + Dietary & Nutrition Consult
    ("vikram@famcare.in", "Post-Surgical Nursing"),
    ("vikram@famcare.in", "Dietary & Nutrition Consult"),
    ("neha@famcare.in", "Post-Surgical Nursing"),
    ("neha@famcare.in", "Dietary & Nutrition Consult"),
    ("rohan@famcare.in", "Post-Surgical Nursing"),
    ("rohan@famcare.in", "Dietary & Nutrition Consult"),

    # Pooja, Manish, Divya: Vital Signs Monitoring + Wound Dressing
    ("pooja@famcare.in", "Vital Signs Monitoring"),
    ("pooja@famcare.in", "Wound Dressing"),
    ("manish@famcare.in", "Vital Signs Monitoring"),
    ("manish@famcare.in", "Wound Dressing"),
    ("divya@famcare.in", "Vital Signs Monitoring"),
    ("divya@famcare.in", "Wound Dressing"),

    # Sandeep, Ritu, Harish: Physiotherapy + Elderly Companion Care
    ("sandeep@famcare.in", "Physiotherapy"),
    ("sandeep@famcare.in", "Elderly Companion Care"),
    ("ritu@famcare.in", "Physiotherapy"),
    ("ritu@famcare.in", "Elderly Companion Care"),
    ("harish@famcare.in", "Physiotherapy"),
    ("harish@famcare.in", "Elderly Companion Care"),

    # Sunita Krishnan, Rajesh Nair, Meera Sen: Medication Review + Occupational Therapy
    ("sunitak@famcare.in", "Medication Review"),
    ("sunitak@famcare.in", "Occupational Therapy"),
    ("rajesh@famcare.in", "Medication Review"),
    ("rajesh@famcare.in", "Occupational Therapy"),
    ("meera@famcare.in", "Medication Review"),
    ("meera@famcare.in", "Occupational Therapy"),

    # Sanjay Dutt: Post-Surgical Nursing
    ("sanjay@famcare.in", "Post-Surgical Nursing"),

    # Kiran Bedi: All 8 services
    ("kiran@famcare.in", "Physiotherapy"),
    ("kiran@famcare.in", "Wound Dressing"),
    ("kiran@famcare.in", "Medication Review"),
    ("kiran@famcare.in", "Elderly Companion Care"),
    ("kiran@famcare.in", "Occupational Therapy"),
    ("kiran@famcare.in", "Post-Surgical Nursing"),
    ("kiran@famcare.in", "Dietary & Nutrition Consult"),
    ("kiran@famcare.in", "Vital Signs Monitoring"),

    # Alok Nath: Elderly Companion Care + Dietary & Nutrition Consult
    ("alok@famcare.in", "Elderly Companion Care"),
    ("alok@famcare.in", "Dietary & Nutrition Consult"),
]

async def seed_db():
    # Make sure tables are created (useful if running independently)
    async with engine.begin() as conn:
        import os
        from sqlalchemy import text
        
        # Self-healing cleaner: Terminate other connection backends on Neon to release active transaction locks immediately
        try:
            await conn.execute(text(
                "SELECT pg_terminate_backend(pid) "
                "FROM pg_stat_activity "
                "WHERE datname = 'neondb' AND pid <> pg_backend_pid();"
            ))
            print("Terminated other active database sessions to free transaction locks.")
        except Exception as e:
            # Safely skip if running on SQLite or under restricted DB privileges
            print(f"Skipped database session termination query: {e}")
            
        # Drop stale tables from previous database states to avoid conflicts
        is_sqlite = "sqlite" in engine.dialect.name
        cascade_suffix = "" if is_sqlite else " CASCADE"
        await conn.execute(text(f"DROP TABLE IF EXISTS bookings{cascade_suffix};"))
        await conn.execute(text(f"DROP TABLE IF EXISTS caregiver_services{cascade_suffix};"))
        await conn.execute(text(f"DROP TABLE IF EXISTS users{cascade_suffix};"))
        await conn.execute(text(f"DROP TABLE IF EXISTS services{cascade_suffix};"))
        print("Dropped stale database tables successfully.")
        
        # Read the raw DDL schema migration
        schema_path = os.path.join(os.path.dirname(__file__), "migrations", "001_initial_schema.sql")
        if os.path.exists(schema_path) and not is_sqlite:
            with open(schema_path, "r", encoding="utf-8") as f:
                ddl_sql = f.read()
            
            # Split statement by semicolon and execute individually to avoid multiple commands in a prepared statement
            statements = ddl_sql.split(";")
            for stmt in statements:
                trimmed = stmt.strip()
                if trimmed:
                    await conn.execute(text(trimmed))
            print("Successfully initialized PostgreSQL database with migrations initial schema DDL.")
        else:
            # Fallback to standard ORM create_all
            import models
            await conn.run_sync(Base.metadata.create_all)
            print("Migration file not found or SQLite in use. Fallback: standard Base metadata create_all initialized.")




    async with async_session() as session:
        # Seed services
        for s_data in SERVICES:
            result = await session.execute(
                select(Service).where(Service.name == s_data["name"])
            )
            existing = result.scalar_one_or_none()
            if not existing:
                service = Service(**s_data)
                session.add(service)
                print(f"Added service: {s_data['name']}")
        
        # Seed users
        for u_data in USERS:
            result = await session.execute(
                select(User).where(User.email == u_data["email"])
            )
            existing = result.scalar_one_or_none()
            if not existing:
                user = User(**u_data)
                session.add(user)
                print(f"Added user: {u_data['name']} ({u_data['role']})")
        
        await session.commit()

        # Seed caregiver services
        for email, service_name in CAREGIVER_SERVICES:
            # Get caregiver id
            result_cg = await session.execute(
                select(User).where(User.email == email)
            )
            cg = result_cg.scalar_one()

            # Get service id
            result_srv = await session.execute(
                select(Service).where(Service.name == service_name)
            )
            srv = result_srv.scalar_one()

            # Check junction
            result_js = await session.execute(
                select(CaregiverService).where(
                    CaregiverService.caregiver_id == cg.id,
                    CaregiverService.service_id == srv.id
                )
            )
            existing = result_js.scalar_one_or_none()
            if not existing:
                cs = CaregiverService(caregiver_id=cg.id, service_id=srv.id)
                session.add(cs)
                print(f"Added qualification: {email} -> {service_name}")
        
        await session.commit()
        print("Database seeding completed successfully.")

if __name__ == "__main__":
    asyncio.run(seed_db())
