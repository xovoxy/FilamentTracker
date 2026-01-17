"""
Test script for the filament recognition API.
Usage: python test_api.py <image_path>
"""
import sys
import requests
import json
from pathlib import Path


def test_api(image_path: str, api_url: str = "http://localhost:8000"):
    """Test the recognition API with an image file."""
    
    if not Path(image_path).exists():
        print(f"Error: Image file not found: {image_path}")
        return
    
    print(f"Testing API at {api_url}")
    print(f"Image: {image_path}")
    print("-" * 50)
    
    # Test health endpoint
    try:
        response = requests.get(f"{api_url}/health", timeout=5)
        print(f"Health check: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Health check failed: {e}")
        return
    
    # Test recognition endpoint
    try:
        with open(image_path, 'rb') as f:
            files = {'image': (Path(image_path).name, f, 'image/jpeg')}
            response = requests.post(
                f"{api_url}/api/v1/recognize",
                files=files,
                timeout=30
            )
        
        print(f"\nRecognition Response:")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Success: {result.get('success')}")
            if result.get('success'):
                print(f"Confidence: {result.get('confidence', 0):.2f}")
                print(f"\nRecognized Data:")
                data = result.get('data', {})
                for key, value in data.items():
                    print(f"  {key}: {value}")
            else:
                print(f"Error: {result.get('error')}")
        else:
            print(f"Error Response: {response.text}")
            
    except requests.exceptions.Timeout:
        print("Error: Request timeout (API may be slow or unavailable)")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_api.py <image_path> [api_url]")
        print("Example: python test_api.py test_image.jpg")
        print("Example: python test_api.py test_image.jpg http://localhost:8000")
        sys.exit(1)
    
    image_path = sys.argv[1]
    api_url = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8000"
    
    test_api(image_path, api_url)
