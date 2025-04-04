//
//  KakaoMapManager.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import Foundation
import CoreLocation

enum KakaoMapError: Error {
  case invalidURL
  case noData
  case decodingError
  case apiError(String)
  case unknown(Error)
}

final class KakaoMapManager {
  
  // MARK: - Properties
  static let shared = KakaoMapManager()
  
  private init() {}
  
  private let apiKey = Key.kakaoMap
  
  // MARK: - Public Methods
  
  /// 주소로 위치 검색
  func searchAddress(query: String) async throws -> [AddressDocument] {
    let endpoint = "https://dapi.kakao.com/v2/local/search/address.json"
    let queryItems = [URLQueryItem(name: "query", value: query)]
    
    let response: AddressSearchResponse = try await request(endpoint: endpoint, queryItems: queryItems)
    return response.documents
  }
  
  /// 위치 기반 키워드 검색 (24시 동물병원)
  func searchHospitals(latitude: Double, longitude: Double, radius: Int = 5000) async throws -> [Hospital] {
    let endpoint = "https://dapi.kakao.com/v2/local/search/keyword.json"
    let queryItems = [
      URLQueryItem(name: "y", value: "\(latitude)"),
      URLQueryItem(name: "x", value: "\(longitude)"),
      URLQueryItem(name: "radius", value: "\(radius)"),
      URLQueryItem(name: "query", value: "24시동물병원")
    ]
    
    let response: KeywordSearchResponse = try await request(endpoint: endpoint, queryItems: queryItems)
    return response.documents.map { $0.toHospital() }
  }
  
  // MARK: - Private Methods
  
  /// API 요청 공통 메서드
  private func request<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> T {
    
    // URL 구성
    guard var urlComponents = URLComponents(string: endpoint) else {
      throw KakaoMapError.invalidURL
    }
    
    urlComponents.queryItems = queryItems
    
    guard let url = urlComponents.url else {
      throw KakaoMapError.invalidURL
    }
    
    // 요청 구성
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    // 카카오 API 인증 헤더 추가
    request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")
    
    // 요청 실행
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      
      // HTTP 상태 확인
      guard let httpResponse = response as? HTTPURLResponse else {
        throw KakaoMapError.unknown(NSError(domain: "HTTPResponse", code: -1))
      }
      
      // 성공 상태 확인
      guard (200...299).contains(httpResponse.statusCode) else {
        throw KakaoMapError.apiError("Status code: \(httpResponse.statusCode)")
      }
      
      // 데이터 디코딩
      do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
      } catch {
        print("Decoding error: \(error)")
        throw KakaoMapError.decodingError
      }
    } catch {
      if let kakaoError = error as? KakaoMapError {
        throw kakaoError
      }
      throw KakaoMapError.unknown(error)
    }
  }
}
