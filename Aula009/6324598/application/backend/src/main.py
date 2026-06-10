from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import logging

from database import engine, Base, get_db
import models, schemas

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Portfolio API", version="1.0.0")

# CORS config
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    logger.info("Health check endpoint called")
    return {"status": "ok", "message": "API is running"}

# --- Projects CRUD ---

@app.get("/api/projects", response_model=list[schemas.Project])
def get_projects(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    projects = db.query(models.Project).offset(skip).limit(limit).all()
    return projects

@app.post("/api/projects", response_model=schemas.Project)
def create_project(project: schemas.ProjectCreate, db: Session = Depends(get_db)):
    db_project = models.Project(**project.model_dump())
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    logger.info(f"Created new project: {db_project.title}")
    return db_project

# --- Experiences CRUD ---

@app.get("/api/experiences", response_model=list[schemas.Experience])
def get_experiences(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    experiences = db.query(models.Experience).offset(skip).limit(limit).all()
    return experiences

@app.post("/api/experiences", response_model=schemas.Experience)
def create_experience(experience: schemas.ExperienceCreate, db: Session = Depends(get_db)):
    db_exp = models.Experience(**experience.model_dump())
    db.add(db_exp)
    db.commit()
    db.refresh(db_exp)
    logger.info(f"Created new experience: {db_exp.role} at {db_exp.company}")
    return db_exp
