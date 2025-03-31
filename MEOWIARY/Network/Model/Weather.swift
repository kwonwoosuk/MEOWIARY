//
//  Weather.swift
//  MEOWIARY
//
//  Created by 권우석 on 3/31/25.
//

import Foundation


struct Weather: Decodable {
    let temperature: Double
    let condition: String
    let humidity: Int
    let windSpeed: Double
}

struct WeatherResponse: Decodable {
    let weather: [WeatherCondition]
    let main: MainWeather
    let wind: Wind
    let name: String
    
    func toWeather() -> Weather {
        return Weather(
            temperature: main.temp,
            condition: weather.first?.main ?? "Clear",
            humidity: main.humidity,
            windSpeed: wind.speed
        )
    }
}

struct WeatherCondition: Decodable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct MainWeather: Decodable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }
}

struct Wind: Decodable {
    let speed: Double
    let deg: Int
}
