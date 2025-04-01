//
//  Hospital.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import Foundation
import CoreLocation

struct HospitalResponse {
    let id: String
    let name: String
    let address: String
    let phone: String
    let latitude: Double
    let longitude: Double
}

struct Hospital {
    let id: String
    let name: String
    let address: String
    let phone: String
    let distance: String
    let coordinate: CLLocationCoordinate2D
    
    init(id: String, name: String, address: String, phone: String, distance: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.distance = distance
        self.coordinate = coordinate
    }
    
    init(from response: HospitalResponse, userLocation: CLLocation) {
        self.id = response.id
        self.name = response.name
        self.address = response.address
        self.phone = response.phone
        
        // 거리 계산
        let hospitalLocation = CLLocation(latitude: response.latitude, longitude: response.longitude)
        let distanceInMeters = userLocation.distance(from: hospitalLocation)
        
        if distanceInMeters < 5000 {
            self.distance = "\(Int(distanceInMeters))m"
        } else {
            let distanceInKM = distanceInMeters / 1000.0
            self.distance = String(format: "%.1fkm", distanceInKM)
        }
        
        self.coordinate = CLLocationCoordinate2D(latitude: response.latitude, longitude: response.longitude)
    }
}
