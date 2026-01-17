//
//  ImageRecognizer.swift
//  FilamentTracker
//
//  Real image recognition service using Python API
//

import Foundation
import UIKit

class ImageRecognizer {
    static let shared = ImageRecognizer()
    
    // API endpoint - configure this to point to your Python service
    private let apiBaseURL = "https://a9orange.xyz/3d"
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    func analyze(_ image: UIImage) async throws -> RecognizedFilamentData {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageRecognizerError.imageConversionFailed
        }
        
        let url = URL(string: "\(apiBaseURL)/api/v1/recognize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageRecognizerError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if let errorData = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    throw ImageRecognizerError.apiError(errorData.error ?? "Unknown error")
                }
                throw ImageRecognizerError.httpError(httpResponse.statusCode)
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            
            guard apiResponse.success, let recognizedData = apiResponse.data else {
                throw ImageRecognizerError.apiError(apiResponse.error ?? "Recognition failed")
            }
            
            // Convert API response to RecognizedFilamentData
            // 将温度信息放入notes字段（通过minTemp字段传递，后续会在AddMaterialView中处理）
            // 注意：这里使用minTemp字段临时存储温度信息字符串，实际会在AddMaterialView中放入notes
            return RecognizedFilamentData(
                brand: recognizedData.brand,
                material: recognizedData.material,
                colorName: recognizedData.colorName,
                colorHex: recognizedData.colorHex,
                weight: recognizedData.weight,
                diameter: recognizedData.diameter,
                minTemp: recognizedData.temperatureInfo,  // 临时使用minTemp传递温度信息
                maxTemp: nil,
                bedTemp: nil
            )
            
        } catch let error as ImageRecognizerError {
            throw error
        } catch {
            throw ImageRecognizerError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Error Types

enum ImageRecognizerError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG format"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - API Response Models

private struct APIResponse: Codable {
    let success: Bool
    let data: RecognizedAPIData?
    let confidence: Double?
    let error: String?
}

private struct RecognizedAPIData: Codable {
    let brand: String?
    let material: String?
    let colorName: String?
    let colorHex: String?
    let weight: String?
    let diameter: Double?
    let temperatureInfo: String?  // 温度信息
}

private struct APIErrorResponse: Codable {
    let success: Bool
    let error: String?
}
