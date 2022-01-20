//
//  Address.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 12/18/18.
//  Copyright © 2018 LMinh. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import Contacts

/// A result from a reverse geocode request, containing a human-readable address.
/// Some of the fields may be nil, indicating they are not present.
public struct Address {

    // MARK: - PROPERTIES
    
    /// The location coordinate.
    public var coordinate: CLLocationCoordinate2D?
    
    /// The precise street address.
    public var streetNumber: String?
    
    /// The named route.
    public var route: String?
    
    /// The incorporated city or town political entity.
    public var locality: String?
    
    /// The first-order civil entity below a localit.
    public var subLocality: String?
    
    /// The civil entity below the country level.
    public var administrativeArea: String?
    
    /// The additional administrative area information.
    public var subAdministrativeArea: String?
    
    /// The neighborhood information.
    public var neighborhood: String?
    
    /// The Postal/Zip code.
    public var postalCode: String?
    
    /// The country name.
    public var country: String?
    
    /// The ISO country code.
    public var isoCountryCode: String?
    
    /// The formatted address.
    public var formattedAddress: String?
    
    /// An array of NSString containing formatted lines of the address.
    public var lines: [String]?
    
    /// The raw source object.
    public var rawSource: Any?
    
    // MARK: - INIT
    
    /// Custom initialization with response from server.
    ///
    /// - Parameters:
    ///   - locationData: Response object recieved from server
    ///   - serviceType: Pass here kLMGeocoderGoogleService or kLMGeocoderAppleService
    init?(locationData: Any, serviceType: GeocoderService) {
        switch serviceType {
        case .apple:
            guard let placemark = locationData as? CLPlacemark else { return nil }
            parseAppleResponse(placemark)
        case .google:
            guard let locationDict = locationData as? [String: Any] else { return nil }
            parseGoogleResponse(locationDict)
        case .here:
            guard let locationDict = locationData as? [String: Any] else { return nil }
            parseHereResponse(locationDict)
        default:
            return nil
        }
    }
    
    // MARK: SUPPORT
    
    private mutating func parseAppleResponse(_ placemark: CLPlacemark) {
        coordinate = placemark.location?.coordinate
        streetNumber = placemark.thoroughfare
        locality = placemark.locality
        subLocality = placemark.subLocality
        administrativeArea = placemark.administrativeArea
        subAdministrativeArea = placemark.subAdministrativeArea
        postalCode = placemark.postalCode
        country = placemark.country
        isoCountryCode = placemark.isoCountryCode
        if #available(iOS 11.0, *) {
            if let postalAddress = placemark.postalAddress {
                formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
            }
        }
        rawSource = placemark
    }
    
    private mutating func parseGoogleResponse(_ locationDict: [String: Any]) {
        let addressComponents = locationDict["address_components"]
        let address = locationDict["formatted_address"] as? String
        
        var lat = 0.0
        var lng = 0.0
        if let geometry = locationDict["geometry"] as? [String: Any] {
            if let location = geometry["location"] as? [String: Any] {
                if let latitude = location["lat"] as? Double {
                    lat = Double(latitude)
                }
                if let longitute = location["lng"] as? Double {
                    lng = Double(longitute)
                }
            }
        }
        
        coordinate = CLLocationCoordinate2DMake(lat, lng)
        streetNumber = getComponent("street_number", inArray: addressComponents, ofType: "long_name")
        route = getComponent("route", inArray: addressComponents, ofType: "long_name")
        locality = getComponent("locality", inArray: addressComponents, ofType: "long_name")
        subLocality = getComponent("sublocality", inArray: addressComponents, ofType: "long_name")
        administrativeArea = getComponent("administrative_area_level_1", inArray: addressComponents, ofType: "long_name")
        subAdministrativeArea = getComponent("administrative_area_level_2", inArray: addressComponents, ofType: "long_name")
        neighborhood = getComponent("neighborhood", inArray: addressComponents, ofType: "long_name")
        postalCode = getComponent("postal_code", inArray: addressComponents, ofType: "short_name")
        country = getComponent("country", inArray: addressComponents, ofType: "long_name")
        isoCountryCode = getComponent("country", inArray: addressComponents, ofType: "short_name")
        formattedAddress = address
        lines = formattedAddress?.components(separatedBy: ", ")
        rawSource = locationDict
    }
    
    private mutating func parseHereResponse(_ locationDict: [String: Any]) {
        guard
            let location = locationDict["Location"] as? [String: Any],
            let addressDict = location["Address"] as? [String: Any]
        else {
            return
        }
        
        var lat = 0.0
        var lng = 0.0
        if let displayPosition = location["DisplayPosition"] as? [String: Any] {
            if let latitude = displayPosition["Latitude"] as? Double {
                lat = Double(latitude)
            }
            if let longitute = displayPosition["Longitude"] as? Double {
                lng = Double(longitute)
            }
        }
        
        coordinate = CLLocationCoordinate2DMake(lat, lng)
        streetNumber = addressDict["HouseNumber"] as? String
        route = addressDict["Street"] as? String
        locality = addressDict["Subdistrict"] as? String
        administrativeArea = addressDict["City"] as? String
        subAdministrativeArea = addressDict["District"] as? String
        country = addressDict["Country"] as? String
        formattedAddress = addressDict["Label"] as? String
        rawSource = locationDict
    }
    
    private func getComponent(_ component: String, inArray array: Any?, ofType type: String) -> String? {

        guard let array = array as? NSArray else { return nil }

        let index = array.indexOfObject { (obj, idx, stop) -> Bool in
            if let componentDict = obj as? [String: Any],
               let types = componentDict["types"] as? [String],
               types.contains(component) {
                return true
            } else {
                return false
            }
        }

        if index == NSNotFound || index >= array.count {
            return nil
        }

        if let dict = array[index] as? [String: Any] {
            return dict[type] as? String
        }
        return nil
    }
}

extension Address: Codable {
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case streetNumber = "street_number"
        case route
        case locality
        case subLocality = "sub_locality"
        case administrativeArea = "administrative_area"
        case subAdministrativeArea = "sub_administrative_area"
        case neighborhood
        case postalCode = "postal_code"
        case country
        case isoCountryCode = "iso_country_code"
        case formattedAddress = "formatted_address"
        case lines
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try values.decode(CLLocationDegrees.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        self.streetNumber = try values.decode(String.self, forKey: .streetNumber)
        self.route = try values.decode(String.self, forKey: .route)
        self.locality = try values.decode(String.self, forKey: .locality)
        self.subLocality = try values.decode(String.self, forKey: .subLocality)
        self.administrativeArea = try values.decode(String.self, forKey: .administrativeArea)
        self.subAdministrativeArea = try values.decode(String.self, forKey: .subAdministrativeArea)
        self.neighborhood = try values.decode(String.self, forKey: .neighborhood)
        self.postalCode = try values.decode(String.self, forKey: .postalCode)
        self.country = try values.decode(String.self, forKey: .country)
        self.isoCountryCode = try values.decode(String.self, forKey: .isoCountryCode)
        self.formattedAddress = try values.decode(String.self, forKey: .formattedAddress)
        self.lines = try values.decode([String].self, forKey: .lines)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate?.latitude, forKey: .latitude)
        try container.encode(coordinate?.longitude, forKey: .longitude)
        try container.encode(streetNumber, forKey: .streetNumber)
        try container.encode(route, forKey: .route)
        try container.encode(locality, forKey: .locality)
        try container.encode(subLocality, forKey: .subLocality)
        try container.encode(administrativeArea, forKey: .administrativeArea)
        try container.encode(subAdministrativeArea, forKey: .subAdministrativeArea)
        try container.encode(neighborhood, forKey: .neighborhood)
        try container.encode(postalCode, forKey: .postalCode)
        try container.encode(country, forKey: .country)
        try container.encode(isoCountryCode, forKey: .isoCountryCode)
        try container.encode(formattedAddress, forKey: .formattedAddress)
        try container.encode(lines, forKey: .lines)
    }
}
