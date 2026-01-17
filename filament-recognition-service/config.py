"""
Configuration management for the recognition service.
"""
import os
from dotenv import load_dotenv
from typing import List

# Load environment variables from .env file
load_dotenv()


class Config:
    """Application configuration."""
    
    # Dashscope API Configuration
    DASHSCOPE_API_KEY: str = os.getenv("DASHSCOPE_API_KEY", "")
    
    # Server Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Model Configuration
    MODEL_NAME: str = os.getenv("MODEL_NAME", "qwen-vl-plus")
    MAX_TOKENS: int = int(os.getenv("MAX_TOKENS", "2000"))
    TEMPERATURE: float = float(os.getenv("TEMPERATURE", "0.1"))
    
    # Image Configuration
    MAX_IMAGE_SIZE_MB: int = int(os.getenv("MAX_IMAGE_SIZE_MB", "10"))
    ALLOWED_IMAGE_TYPES: List[str] = os.getenv(
        "ALLOWED_IMAGE_TYPES", "jpeg,jpg,png"
    ).lower().split(",")
    
    @classmethod
    def validate(cls) -> None:
        """Validate required configuration."""
        if not cls.DASHSCOPE_API_KEY:
            raise ValueError(
                "DASHSCOPE_API_KEY is required. Please set it in .env file or environment variable."
            )
    
    @classmethod
    def get_max_image_size_bytes(cls) -> int:
        """Get maximum image size in bytes."""
        return cls.MAX_IMAGE_SIZE_MB * 1024 * 1024


# Global config instance
config = Config()
