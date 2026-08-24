from fastapi import FastAPI, UploadFile, File, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import pandas as pd
import numpy as np
import io
from database import get_db, Telemetry, SessionMeta

app = FastAPI(title="Telemetry Ingestion API")

# Allow frontend to communicate with backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/api/upload")
async def upload_session(
        session_id: str,
        file: UploadFile = File(...),
        db: Session = Depends(get_db)
):
    # Read CSV into Pandas
    contents = await file.read()
    df = pd.read_csv(io.StringIO(contents.decode('utf-8')))

    # Data Cleaning & ETL
    df['speed'] = pd.to_numeric(df['speed'], errors='coerce')
    df['wheel_angle'] = pd.to_numeric(df['wheel_angle'], errors='coerce')

    # Neutralize hardware outliers noted in the metadata
    # (better method - average adjacent values)
    df.loc[df['wheel_angle'] == -999.00, 'wheel_angle'] = np.nan
    df.loc[df['speed'] > 200, 'speed'] = np.nan

    # Interpolate missing data to smooth out sensor drops
    df['speed'] = df['speed'].interpolate(method='linear').bfill().ffill()
    df['wheel_angle'] = df['wheel_angle'].interpolate(method='linear').bfill().ffill()

    # Parse timestamps
    df['timestamp'] = pd.to_datetime(df['timestamp'], format='%d/%m/%Y %H:%M')

    # Database insertion
    try:
        # Save Metadata
        new_session = SessionMeta(session_id=session_id)    #, vehicle_id=vehicle_id, notes=notes)
        db.add(new_session)

        # Bulk insert telemetry
        telemetry_records = []
        for _, row in df.iterrows():
            telemetry_records.append(
                Telemetry(
                    session_id=session_id,
                    timestamp=row['timestamp'],
                    wheel_angle=row['wheel_angle'],
                    speed=row['speed'],
                    reverse_state=row['reverse_state']
                )
            )
        db.bulk_save_objects(telemetry_records)
        db.commit()
        return {"message": f"Successfully ingested {len(telemetry_records)} records for {session_id}"}

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/sessions/{session_id}/data")
def get_session_data(session_id: str, db: Session = Depends(get_db)):
    data = db.query(Telemetry).filter(Telemetry.session_id == session_id).order_by(Telemetry.timestamp).all()
    if not data:
        raise HTTPException(status_code=404, detail="Session not found")
    return data