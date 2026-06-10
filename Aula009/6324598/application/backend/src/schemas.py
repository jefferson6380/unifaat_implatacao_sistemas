from pydantic import BaseModel
from typing import Optional

class ProjectBase(BaseModel):
    title: str
    description: str
    url: Optional[str] = None

class ProjectCreate(ProjectBase):
    pass

class Project(ProjectBase):
    id: int

    class Config:
        orm_mode = True
        from_attributes = True

class ExperienceBase(BaseModel):
    role: str
    company: str
    period: str
    description: str

class ExperienceCreate(ExperienceBase):
    pass

class Experience(ExperienceBase):
    id: int

    class Config:
        orm_mode = True
        from_attributes = True
