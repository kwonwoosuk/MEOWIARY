//
//  WeatherService.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import Foundation
import CoreLocation

enum WeatherError: Error {
    case invalidURL
    case noData
    case decodingError
    case locationError
    case networkError(Error)
}



class WeatherService {
    
    // MARK: - Properties
    private let apiKey = Key.Weather
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private let locationManager = CLLocationManager()
    
    // MARK: - Public Methods
    
    /// 현재 위치의 날씨 정보 가져오기 (Async/Await)
    func fetchCurrentWeather() async -> Result<Weather, WeatherError> {
        do {
            // 위치 정보 가져오기
            let location = try await getCurrentLocation()
            
            // 위치를 기반으로 날씨 정보 가져오기
            return try await fetchWeather(latitude: location.latitude, longitude: location.longitude)
        } catch {
            if let weatherError = error as? WeatherError {
                return .failure(weatherError)
            }
            return .failure(.networkError(error))
        }
    }
    
    /// 도시명으로 날씨 정보 가져오기 (Async/Await)
    func fetchWeather(cityName: String) async -> Result<Weather, WeatherError> {
        do {
            let weather = try await NetworkManager.shared.fetchWeatherByCity(cityName: cityName, apiKey: apiKey)
            return .success(weather)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    /// 위도/경도로 날씨 정보 가져오기 (Async/Await)
    func fetchWeather(latitude: Double, longitude: Double) async -> Result<Weather, WeatherError> {
        do {
            // WeatherResponse를 받아서 Weather로 변환
            let response: WeatherResponse = try await NetworkManager.shared.fetchWeather(
                latitude: latitude,
                longitude: longitude,
                apiKey: apiKey
            )
            // 응답을 Weather 객체로 변환
            let weather = Weather(
                temperature: response.main.temp,
                condition: response.weather.first?.main ?? "Clear",
                humidity: response.main.humidity,
                windSpeed: response.wind.speed
            )
            return .success(weather)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    // MARK: - Private Methods
    
    /// 현재 위치 가져오기 (Async/Await)
    private func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        // 위치 서비스 사용 가능 확인
        if CLLocationManager.locationServicesEnabled() {
            // 실제 앱에서는 여기서 위치 권한 요청 및 확인 로직 추가 필요
            
            // 시뮬레이터 테스트를 위한 기본 위치 (서울)
            let defaultLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            
            // 현재 위치가 있으면 해당 위치 반환, 없으면 기본 위치 반환
            if let location = locationManager.location {
                return location.coordinate
            } else {
                return defaultLocation
            }
        } else {
            throw WeatherError.locationError
        }
    }
}



