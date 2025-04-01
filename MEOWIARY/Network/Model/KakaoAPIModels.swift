//
//  KakaoMapModels.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import Foundation
import CoreLocation

// MARK: - 주소 검색 응답 모델
struct AddressSearchResponse: Codable {
    let documents: [AddressDocument]
    let meta: Meta
}

struct AddressDocument: Codable {
    let addressName: String
    let addressType: String
    let x, y: String
    let address: Address?
    let roadAddress: RoadAddress?
    
    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case addressType = "address_type"
        case x, y, address
        case roadAddress = "road_address"
    }
    
    // 위치 좌표로 변환
    var coordinate: CLLocationCoordinate2D {
        guard let latitude = Double(y), let longitude = Double(x) else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Address: Codable {
    let addressName, region1depthName, region2depthName, region3depthName: String
    let mountainYn, mainAddressNo, subAddressNo: String
    let x, y: String
    
    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case region1depthName = "region_1depth_name"
        case region2depthName = "region_2depth_name"
        case region3depthName = "region_3depth_name"
        case mountainYn = "mountain_yn"
        case mainAddressNo = "main_address_no"
        case subAddressNo = "sub_address_no"
        case x, y
    }
}

struct RoadAddress: Codable {
    let addressName, region1depthName, region2depthName, region3depthName: String
    let roadName, mainBuildingNo, subBuildingNo: String
    let buildingName: String
    let x, y: String
    
    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case region1depthName = "region_1depth_name"
        case region2depthName = "region_2depth_name"
        case region3depthName = "region_3depth_name"
        case roadName = "road_name"
        case mainBuildingNo = "main_building_no"
        case subBuildingNo = "sub_building_no"
        case buildingName = "building_name"
        case x, y
    }
}

// MARK: - 키워드 검색 응답 모델
struct KeywordSearchResponse: Codable {
    let documents: [PlaceDocument]
    let meta: Meta
}

struct PlaceDocument: Codable {
    let id: String
    let placeName: String
    let addressName: String
    let roadAddressName: String
    let x, y: String
    let phone: String
    let categoryGroupName: String
    let distance: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x, y, phone
        case categoryGroupName = "category_group_name"
        case distance
    }
    
    // Hospital 모델로 변환
    func toHospital() -> Hospital {
        let coordinate = CLLocationCoordinate2D(
            latitude: Double(y) ?? 0,
            longitude: Double(x) ?? 0
        )
        
        return Hospital(
            id: id,
            name: placeName,
            address: roadAddressName.isEmpty ? addressName : roadAddressName,
            phone: phone,
            distance: formatDistance(distance),
            coordinate: coordinate
        )
    }
    
    // 거리 포맷팅
    private func formatDistance(_ distanceString: String) -> String {
        guard let distance = Double(distanceString) else { return "거리 정보 없음" }
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000.0
            return String(format: "%.1fkm", km)
        }
    }
}

struct Meta: Codable {
    let isEnd: Bool
    let pageableCount: Int
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case isEnd = "is_end"
        case pageableCount = "pageable_count"
        case totalCount = "total_count"
    }
}


