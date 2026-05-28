import asyncio
import database
import os

print(f"database imported from: {database.__file__}")
print(f"Current working directory: {os.getcwd()}")
print(f"Absolute path of database.py: {os.path.abspath(database.__file__)}")

from database import DATABASE_URL, engine

async def test():
    print(f"DATABASE_URL is: {DATABASE_URL}")

if __name__ == "__main__":
    asyncio.run(test())
