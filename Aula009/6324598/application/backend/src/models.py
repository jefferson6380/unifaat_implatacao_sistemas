from sqlalchemy import Column, Integer, String, Text
from database import Base

class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(Text)
    url = Column(String, nullable=True)

class Experience(Base):
    __tablename__ = "experiences"

    id = Column(Integer, primary_key=True, index=True)
    role = Column(String, index=True)
    company = Column(String)
    period = Column(String)
    description = Column(Text)
