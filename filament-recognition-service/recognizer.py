"""
Core image recognition logic using dashscope qwen3-vl-plus model.
"""
import json
import base64
import io
from typing import Optional, Dict, Any, Tuple
import logging
from PIL import Image
import dashscope
from dashscope import MultiModalConversation

from config import config
from models import RecognizedFilamentData

logger = logging.getLogger(__name__)


# Prompt template for structured data extraction
PROMPT_TEMPLATE = """请分析这张3D打印耗材标签图片，提取以下信息并以JSON格式返回：

1. brand (品牌): 如 "Bambu Lab", "Polymaker", "Sunlu", "eSUN", "Creality", "Prusa", "Hatchbox", "Overture" 等
2. material (材料类型): 如 "PLA", "PETG", "ABS", "PLA+", "TPU", "ASA", "PA", "PC" 等
3. colorName (颜色名称): 如 "Matte Charcoal", "Teal Blue", "Silk Gold", "Black", "White" 等
4. colorHex (颜色十六进制): 根据图片中的实际颜色或颜色描述推断，格式为 "#RRGGBB"，如 "#333333", "#008080", "#FFD700"
5. weight (重量): 以克(g)为单位，只返回数字字符串，如 "1000", "500", "250"
6. diameter (直径): 1.75 或 2.85，返回数字类型

如果某个信息无法识别或图片中没有相关信息，请返回 null。

请严格按照以下JSON格式返回，不要添加任何其他文字、说明或markdown代码块标记：
{
  "brand": "品牌名称或null",
  "material": "材料类型或null",
  "colorName": "颜色名称或null",
  "colorHex": "#颜色代码或null",
  "weight": "重量数字字符串或null",
  "diameter": 1.75或2.85或null
}
"""


class ImageRecognizer:
    """Image recognizer using dashscope qwen3-vl-plus model."""
    
    def __init__(self):
        """Initialize the recognizer with API key."""
        if not config.DASHSCOPE_API_KEY:
            raise ValueError("DASHSCOPE_API_KEY is not configured")
        
        dashscope.api_key = config.DASHSCOPE_API_KEY
    
    def _image_to_base64(self, image: Image.Image) -> str:
        """Convert PIL Image to base64 string."""
        buffered = io.BytesIO()
        # Convert to RGB if necessary (for PNG with transparency)
        if image.mode in ('RGBA', 'LA', 'P'):
            # Create a white background
            rgb_image = Image.new('RGB', image.size, (255, 255, 255))
            if image.mode == 'P':
                image = image.convert('RGBA')
            rgb_image.paste(image, mask=image.split()[-1] if image.mode == 'RGBA' else None)
            image = rgb_image
        elif image.mode != 'RGB':
            image = image.convert('RGB')
        
        image.save(buffered, format="JPEG", quality=85)
        img_str = base64.b64encode(buffered.getvalue()).decode()
        return img_str
    
    def _parse_json_response(self, text: str) -> Optional[Dict[str, Any]]:
        """Parse JSON from model response text."""
        # Try to extract JSON from the response
        text = text.strip()
        
        # Remove markdown code blocks if present
        if text.startswith("```json"):
            text = text[7:]
        elif text.startswith("```"):
            text = text[3:]
        
        if text.endswith("```"):
            text = text[:-3]
        
        text = text.strip()
        
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            # Try to find JSON object in the text
            start_idx = text.find("{")
            end_idx = text.rfind("}")
            if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                try:
                    return json.loads(text[start_idx:end_idx + 1])
                except json.JSONDecodeError:
                    pass
        
        return None
    
    def _validate_and_normalize(self, data: Dict[str, Any]) -> RecognizedFilamentData:
        """Validate and normalize recognized data."""
        # Normalize diameter
        diameter = data.get("diameter")
        if diameter is not None:
            if isinstance(diameter, str):
                try:
                    diameter = float(diameter)
                except ValueError:
                    diameter = None
            if diameter not in [1.75, 2.85]:
                diameter = None
        
        # Normalize weight (ensure it's a string)
        weight = data.get("weight")
        if weight is not None and not isinstance(weight, str):
            weight = str(weight)
        
        # Normalize colorHex (ensure it starts with #)
        color_hex = data.get("colorHex")
        if color_hex and not color_hex.startswith("#"):
            color_hex = "#" + color_hex
        
        return RecognizedFilamentData(
            brand=data.get("brand"),
            material=data.get("material"),
            colorName=data.get("colorName"),
            colorHex=color_hex,
            weight=weight,
            diameter=diameter
        )
    
    async def recognize(self, image: Image.Image) -> Tuple[RecognizedFilamentData, float]:
        """
        Recognize filament information from image.
        
        Args:
            image: PIL Image object
            
        Returns:
            Tuple of (RecognizedFilamentData, confidence_score)
            
        Raises:
            Exception: If recognition fails
        """
        try:
            # Convert image to base64
            image_base64 = self._image_to_base64(image)
            
            # Prepare messages for multimodal conversation
            messages = [
                {
                    "role": "user",
                    "content": [
                        {
                            "image": f"data:image/jpeg;base64,{image_base64}"
                        },
                        {
                            "text": PROMPT_TEMPLATE
                        }
                    ]
                }
            ]
            
            # Call dashscope API
            response = MultiModalConversation.call(
                model=config.MODEL_NAME,
                messages=messages,
                max_tokens=config.MAX_TOKENS,
                temperature=config.TEMPERATURE
            )
            
            # Check if request was successful
            if response.status_code != 200:
                error_msg = f"API request failed with status {response.status_code}"
                if hasattr(response, 'message'):
                    error_msg += f": {response.message}"
                raise Exception(error_msg)
            
            # Extract text from response
            # content[0] is a dict with "text" key, not an object with .text attribute
            try:
                content_item = response.output.choices[0].message.content[0]
                logger.debug(f"Content item type: {type(content_item)}, value: {content_item}")
                
                if isinstance(content_item, dict):
                    output_text = content_item.get("text", "")
                else:
                    # Fallback for older API versions that might use object attributes
                    output_text = getattr(content_item, "text", "")
                
                if not output_text:
                    # Log the full response structure for debugging
                    logger.error(f"Response structure: {json.dumps(response.output.choices[0].message.content, indent=2, default=str)}")
                    raise Exception("No text content found in API response")
                    
            except (IndexError, AttributeError, KeyError) as e:
                logger.error(f"Error extracting text from response: {e}")
                logger.error(f"Response structure: {response.output if hasattr(response, 'output') else 'No output'}")
                raise Exception(f"Failed to extract text from API response: {str(e)}")
            
            # Parse JSON response
            parsed_data = self._parse_json_response(output_text)
            
            if not parsed_data:
                raise Exception("Failed to parse JSON from model response")
            
            # Validate and normalize data
            recognized_data = self._validate_and_normalize(parsed_data)
            
            # Calculate confidence (simple heuristic based on number of fields filled)
            filled_fields = sum([
                1 if recognized_data.brand else 0,
                1 if recognized_data.material else 0,
                1 if recognized_data.colorName else 0,
                1 if recognized_data.colorHex else 0,
                1 if recognized_data.weight else 0,
                1 if recognized_data.diameter else 0,
            ])
            confidence = filled_fields / 6.0
            
            return recognized_data, confidence
            
        except Exception as e:
            raise Exception(f"Recognition failed: {str(e)}")


# Global recognizer instance
_recognizer: Optional[ImageRecognizer] = None


def get_recognizer() -> ImageRecognizer:
    """Get or create recognizer instance."""
    global _recognizer
    if _recognizer is None:
        _recognizer = ImageRecognizer()
    return _recognizer
