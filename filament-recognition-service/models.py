"""
Data models for filament recognition service.
"""
from pydantic import BaseModel
from typing import Optional


class RecognizedFilamentData(BaseModel):
    """Recognized filament data structure."""
    brand: Optional[str] = None
    material: Optional[str] = None
    colorName: Optional[str] = None
    colorHex: Optional[str] = None
    weight: Optional[str] = None
    diameter: Optional[float] = None
    temperatureInfo: Optional[str] = None  # 温度信息，将放入notes字段


class RecognitionResponse(BaseModel):
    """API response model for recognition results."""
    success: bool
    data: Optional[RecognizedFilamentData] = None
    confidence: Optional[float] = None
    error: Optional[str] = None
