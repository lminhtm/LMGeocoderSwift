//
//  LMAddress.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 12/18/18.
//  Copyright © 2018 LMinh. All rights reserved.
//

import UIKit
import CoreLocation
import Contacts

/// A result from a reverse geocode request, containing a human-readable address.
/// Some of the fields may be nil, indicating they are not present.
public struct LMAddress {

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
    public var ISOcountryCode: String?
    
    /// The formatted address.
    public var formattedAddress: String?
    
    /// An array of NSString containing formatted lines of the address.
    public var lines: [String]?
    
    /// The raw source object.
    public var rawSource: AnyObject?
    
    // MARK: - INIT
    
    /// Custom initialization with response from server.
    ///
    /// - Parameters:
    ///   - locationData: Response object recieved from server
    ///   - serviceType: Pass here kLMGeocoderGoogleService or kLMGeocoderAppleService
    init(locationData: AnyObject, serviceType: LMGeocoderService) {
        switch serviceType {
        case .AppleService:
            self.parseAppleResponse(locationData: locationData)
        default:
            self.parseGoogleResponse(locationData: locationData)
        }
    }
    
    // MARK: SUPPORT
    
    private mutating func parseAppleResponse(locationData: AnyObject) {
        
        guard let placemark = locationData as? CLPlacemark else { return }
        
        coordinate = placemark.location?.coordinate
        streetNumber = placemark.thoroughfare
        locality = placemark.locality
        subLocality = placemark.subLocality
        administrativeArea = placemark.administrativeArea
        subAdministrativeArea = placemark.subAdministrativeArea
        postalCode = placemark.postalCode
        country = placemark.country
        ISOcountryCode = placemark.isoCountryCode
        if #available(iOS 11.0, *) {
            if let postalAddress = placemark.postalAddress {
                formattedAddress = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
            }
        }
        rawSource = placemark
    }
    
    private mutating func parseGoogleResponse(locationData: AnyObject) {
        
        guard let locationDict = locationData as? Dictionary<String, Any> else { return }
        
        let addressComponents = locationDict["address_components"]
        let formattedAddress = locationDict["formatted_address"] as? String
        
        var lat = 0.0
        var lng = 0.0
        if let geometry = locationDict["geometry"] as? Dictionary<String, Any> {
            if let location = geometry["location"] as? Dictionary<String, Any> {
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
        ISOcountryCode = getComponent("country", inArray: addressComponents, ofType: "short_name")
        self.formattedAddress = formattedAddress
        lines = formattedAddress?.components(separatedBy: ", ")
        rawSource = locationData
    }
    
    private func getComponent(_ component: String, inArray array: Any?, ofType type: String) -> String? {
        
        guard let array = array as? NSArray else { return nil }
        
        let index = array.indexOfObject { (obj, idx, stop) -> Bool in
            return false
        }
        
        if index == NSNotFound || index >= array.count {
            return nil
        }
        
        if let dict = array[index] as? [String: Any] {
            return dict[type] as? String
        }
        return nil;
    }
}
