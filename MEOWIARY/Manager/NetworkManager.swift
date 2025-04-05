//
//  NetworkManager.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int)
    case unknown(Error)
}

final class NetworkManager {
    
    // MARK: - Singleton
    static let shared = NetworkManager()
    
    private init() {}
    
    // MARK: - Properties
    private let session = URLSession.shared
    
    // MARK: - Public Methods
    
    /// 비동기 데이터 요청 (Swift Concurrency)
    func request<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil,
        httpMethod: String = "GET",
        headers: [String: String]? = nil
    ) async throws -> T {
        
        // URL 생성
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        // 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // 기본 헤더 설정
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 추가 헤더 설정
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 요청 전송 및 응답 처리
        do {
            let (data, response) = try await session.data(for: request)
            
            // HTTP 상태 코드 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "HTTPResponse", code: -1))
            }
            
            // 성공 상태 코드 확인 (200-299)
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            // 데이터 디코딩
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                return decodedData
            } catch {
                throw NetworkError.decodingError
            }
        } catch let urlError as URLError {
            throw NetworkError.unknown(urlError)
        } catch {
            throw error
        }
    }
    
    /// 날씨 API 요청을 위한 편의 메서드
    func fetchWeather(latitude: Double, longitude: Double, apiKey: String) async throws -> WeatherResponse {
        let endpoint = "https://api.openweathermap.org/data/2.5/weather"
        let queryItems = [
            URLQueryItem(name: "lat", value: "\(latitude)"),
            URLQueryItem(name: "lon", value: "\(longitude)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        return try await request(endpoint: endpoint, queryItems: queryItems)
    }
    
    /// 도시 이름으로 날씨 정보 요청
    func fetchWeatherByCity(cityName: String, apiKey: String) async throws -> Weather {
        let endpoint = "https://api.openweathermap.org/data/2.5/weather"
        let queryItems = [
            URLQueryItem(name: "q", value: cityName),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        return try await request(endpoint: endpoint, queryItems: queryItems)
    }
}
