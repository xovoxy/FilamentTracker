"""
FastAPI application for filament image recognition service.
"""
import io
import logging
from typing import List
from fastapi import FastAPI, File, UploadFile, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image

from config import config, Config
from models import RecognitionResponse, RecognizedFilamentData
from recognizer import get_recognizer

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Validate configuration on startup
try:
    Config.validate()
except ValueError as e:
    logger.error(f"Configuration error: {e}")
    raise

# Create FastAPI app
app = FastAPI(
    title="Filament Recognition Service",
    description="3D打印耗材标签图像识别服务，基于qwen3-vl-plus模型",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS if "*" not in config.CORS_ORIGINS else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    logger.info("Starting Filament Recognition Service...")
    logger.info(f"Model: {config.MODEL_NAME}")
    logger.info(f"Server: {config.HOST}:{config.PORT}")
    
    # Initialize recognizer
    try:
        get_recognizer()
        logger.info("Recognizer initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize recognizer: {e}")
        raise


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "service": "Filament Recognition Service",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


def validate_image_file(file: UploadFile) -> None:
    """Validate uploaded image file."""
    # Check file extension
    file_ext = file.filename.split(".")[-1].lower() if file.filename else ""
    if file_ext not in config.ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported image type. Allowed types: {', '.join(config.ALLOWED_IMAGE_TYPES)}"
        )
    
    # Check file size (if available)
    if hasattr(file, 'size') and file.size:
        max_size = config.get_max_image_size_bytes()
        if file.size > max_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image file too large. Maximum size: {config.MAX_IMAGE_SIZE_MB}MB"
            )


async def load_image_from_upload(file: UploadFile) -> Image.Image:
    """Load PIL Image from uploaded file."""
    try:
        # Read file content
        contents = await file.read()
        
        # Check size
        max_size = config.get_max_image_size_bytes()
        if len(contents) > max_size:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image file too large. Maximum size: {config.MAX_IMAGE_SIZE_MB}MB"
            )
        
        # Open image with PIL
        image = Image.open(io.BytesIO(contents))
        
        # Verify it's a valid image
        image.verify()
        
        # Reopen for actual use (verify() closes the image)
        image = Image.open(io.BytesIO(contents))
        
        return image
        
    except Exception as e:
        logger.error(f"Failed to load image: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid image file: {str(e)}"
        )


@app.post("/api/v1/recognize", response_model=RecognitionResponse)
async def recognize_filament(image: UploadFile = File(...)):
    """
    Recognize filament information from uploaded image.
    
    Args:
        image: Image file (JPEG, PNG)
        
    Returns:
        RecognitionResponse with recognized data
    """
    try:
        # Validate file
        validate_image_file(image)
        
        # Load image
        logger.info(f"Processing image: {image.filename}")
        pil_image = await load_image_from_upload(image)
        
        # Get recognizer and perform recognition
        recognizer = get_recognizer()
        recognized_data, confidence = await recognizer.recognize(pil_image)
        
        logger.info(f"Recognition successful. Confidence: {confidence:.2f}")
        
        return RecognitionResponse(
            success=True,
            data=recognized_data,
            confidence=confidence
        )
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        logger.error(f"Recognition error: {e}", exc_info=True)
        return RecognitionResponse(
            success=False,
            error=str(e)
        )


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": "Internal server error"
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host=config.HOST,
        port=config.PORT,
        reload=True
    )
