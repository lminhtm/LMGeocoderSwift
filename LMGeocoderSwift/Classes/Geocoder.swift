//
//  Geocoder.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 12/18/18.
//  Copyright © 2018 LMinh. All rights reserved.
//

import UIKit
import CoreLocation

/// LMGeocoder error codes.
public enum GeocoderError: Error {
    case invalidCoordinate
    case invalidAddressString
}

/// LMGeocoder service API.
public enum GeocoderService {
    case GoogleService
    case AppleService
}

/// Google Geocoding API const
private let googleGeocodingURLString = "https://maps.googleapis.com/maps/api/geocode/json?sensor=true"

/// Handler that reports a geocoding response, or error.
public typealias GeocodeCallback = (_ results: [Address]?, _ error: Error?) -> Void

/// Exposes a service for geocoding and reverse geocoding.
open class Geocoder {
    
    // MARK: - PROPERTIES
    
    /// Indicating whether the receiver is in the middle of geocoding its value.
    private(set) var isGeocoding: Bool = false
    
    /// To set google API key.
    public var googleAPIKey: String? = nil
    
    /// Apple Geocoder.
    private lazy var appleGeocoder: CLGeocoder = CLGeocoder()
    
    /// Google Geocoder Task
    private lazy var googleGeocoderTask: URLSessionDataTask? = nil
    
    // MARK: SINGLETON
    
    public static let shared = Geocoder()
    
    // MARK: GEOCODING
    
    /// Submits a forward-geocoding request using the specified string.
    /// After initiating a forward-geocoding request, do not attempt to initiate another forward- or reverse-geocoding request.
    /// Geocoding requests are rate-limited for each app, so making too many requests in a
    /// short period of time may cause some of the requests to fail.
    /// When the maximum rate is exceeded, the geocoder passes an error object to your completion handler.
    ///
    /// - Parameters:
    ///   - address: The string describing the location you want to look up.
    ///   - service: The service API used to geocode.
    ///   - completionHandler: The callback to invoke with the geocode results. The callback will be invoked asynchronously from the main thread.
    public func geocode(_ address: String, service: GeocoderService, completionHandler: GeocodeCallback?) {
        
        isGeocoding = true
        
        // Check adress string
        guard address.count != 0 else {
            
            isGeocoding = false
            if let completionHandler = completionHandler {
                completionHandler(nil, GeocoderError.invalidAddressString)
            }
            return
        }
        
        // Check service
        if service == .GoogleService
        {
            // Geocode using Google service
            var urlString = googleGeocodingURLString + "&address=\(address)"
            if let key = googleAPIKey {
                urlString = urlString + "&key=" + key
            }
            buildAsynchronousRequest(urlString: urlString) { (results, error) in
                
                self.isGeocoding = false
                if let completionHandler = completionHandler {
                    completionHandler(results, error)
                }
            }
        }
        else if service == .AppleService
        {
            // Geocode using Apple service
            appleGeocoder.geocodeAddressString(address) { (placemarks, error) in
                
                let results = self.parseGeocodingResponse(placemarks, service: .AppleService)
                
                self.isGeocoding = false
                if let completionHandler = completionHandler {
                    completionHandler(results, error)
                }
            }
        }
    }
    
    /// Submits a reverse-geocoding request for the specified coordinate.
    /// After initiating a reverse-geocoding request, do not attempt to initiate another reverse- or forward-geocoding request.
    /// Geocoding requests are rate-limited for each app, so making too many requests in a
    /// short period of time may cause some of the requests to fail.
    /// When the maximum rate is exceeded, the geocoder passes an error object to your completion handler.
    ///
    /// - Parameters:
    ///   - address: The coordinate to look up.
    ///   - service: The service API used to reverse geocode.
    ///   - completionHandler: The callback to invoke with the reverse geocode results.The callback will be invoked asynchronously from the main thread.
    public func reverseGeocode(_ coordinate: CLLocationCoordinate2D, service: GeocoderService, completionHandler: GeocodeCallback?) {
        
        isGeocoding = true
        
        // Check location coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            
            isGeocoding = false
            if let completionHandler = completionHandler {
                completionHandler(nil, GeocoderError.invalidCoordinate)
            }
            return
        }
        
        // Check service
        if service == .GoogleService
        {
            // Reverse geocode using Google service
            var urlString = googleGeocodingURLString + "&latlng=\(coordinate.latitude),\(coordinate.longitude)"
            if let key = googleAPIKey {
                urlString = urlString + "&key=" + key
            }
            buildAsynchronousRequest(urlString: urlString) { (results, error) in
                
                self.isGeocoding = false
                if let completionHandler = completionHandler {
                    completionHandler(results, error)
                }
            }
        }
        else if service == .AppleService
        {
            // Reverse geocode using Apple service
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            appleGeocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                
                let results = self.parseGeocodingResponse(placemarks, service: .AppleService)
                
                self.isGeocoding = false
                if let completionHandler = completionHandler {
                    completionHandler(results, error)
                }
            }
        }
    }
    
    /// Cancels a pending geocoding request.
    public func cancelGeocode() {
        appleGeocoder.cancelGeocode()
        googleGeocoderTask?.cancel()
    }
}

// MARK: - SUPPORT

extension Geocoder {
    
    /// Build asynchronous request
    func buildAsynchronousRequest(urlString: String, completionHandler: GeocodeCallback?) {
        
        let urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = URL(string: urlString)!
        
        googleGeocoderTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            if let data = data, error == nil {
                
                do {
                    let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String, Any>
                    
                    // Check status value
                    if let status = result["status"] as? String, status == "OK" {
                        // Status OK --> Parse response results
                        let locationDicts = result["results"] as? [AnyObject]
                        let finalResults = self.parseGeocodingResponse(locationDicts, service: .GoogleService)
                        if let completionHandler = completionHandler {
                            completionHandler(finalResults, nil)
                        }
                    }
                    else {
                        // Other status --> Return error
                        if let completionHandler = completionHandler {
                            completionHandler(nil, error)
                        }
                    }
                }
                catch {
                    // Parse failed --> Return error
                    if let completionHandler = completionHandler {
                        completionHandler(nil, error)
                    }
                }
            }
            else {
                // Request failed --> Return error
                if let completionHandler = completionHandler {
                    completionHandler(nil, error)
                }
            }
        })
        googleGeocoderTask?.resume()
    }
    
    /// Parse geocoding response
    func parseGeocodingResponse(_ results: [AnyObject]?, service: GeocoderService) -> [Address]? {
        
        guard let results = results else { return nil }
        
        var finalResults = [Address]()
        for respondObject in results {
            let address = Address(locationData: respondObject, serviceType: service)
            finalResults.append(address)
        }
        return finalResults
    }
}
