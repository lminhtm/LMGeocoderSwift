//
//  GeocodingOperation.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 8/26/19.
//

import Foundation
import CoreLocation

/// LMGeocoder error codes.
public enum GeocoderError: Error {
    case invalidCoordinate
    case invalidAddressString
    case geocodeInternal
}

/// LMGeocoder service API.
public enum GeocoderService {
    case undefined
    case google
    case apple
    case here
}

/// Geocoding API const
let googleGeocodingURLString = "https://maps.googleapis.com/maps/api/geocode/json"
let hereGeocodingURLString = "https://geocoder.api.here.com/6.2/geocode.json"
let hereReverseGeocodingURLString = "https://reverse.geocoder.api.here.com/6.2/reversegeocode.json"

/// Handler that reports a geocoding response, or error.
public typealias GeocodeCallback = (_ results: [Address]?, _ error: Error?) -> Void

/// An abstract class that makes building simple asynchronous operations easy.
class GeocodingOperation: AsynchronousOperation {
    
    // MARK: PROPERTIES
    
    let addressString: String?
    let coordinate: CLLocationCoordinate2D?
    let service: GeocoderService
    let alternativeService: GeocoderService
    let completionHandler: GeocodeCallback?
    let isReverseGeocoding: Bool
    
    let googleAPIKey: String?
    let hereAppId: String?
    let hereAppCode: String?
    
    /// Apple Geocoder.
    private var appleGeocoder: CLGeocoder? = nil
    
    /// Google & Here Geocoder Task
    private var geocoderTask: URLSessionDataTask? = nil
    
    // MARK: INIT
    
    init(addressString: String? = nil,
         coordinate: CLLocationCoordinate2D? = nil,
         isReverseGeocoding: Bool,
         service: GeocoderService,
         alternativeService: GeocoderService = .undefined,
         googleAPIKey: String? = nil,
         hereAppId: String? = nil,
         hereAppCode: String? = nil,
         completionHandler: GeocodeCallback? = nil) {
        
        self.addressString = addressString
        self.coordinate = coordinate
        self.isReverseGeocoding = isReverseGeocoding
        self.service = service
        self.alternativeService = alternativeService
        self.googleAPIKey = googleAPIKey
        self.hereAppId = hereAppId
        self.hereAppCode = hereAppCode
        self.completionHandler = completionHandler
        
        super.init()
    }
    
    // MARK: CONTROL
    
    override func cancel() {
        super.cancel()
        appleGeocoder?.cancelGeocode()
        geocoderTask?.cancel()
    }
    
    override func execute() {
        if isReverseGeocoding {
            reverseGeocodeCoordinate(coordinate,
                                     service: service,
                                     alternativeService: alternativeService,
                                     completionHandler: completionHandler)
        }
        else {
            geocodeAddressString(addressString,
                                 service: service,
                                 alternativeService: alternativeService,
                                 completionHandler: completionHandler)
        }
    }
    
    // MARK: GEOCODE
    
    func geocodeAddressString(_ addressString: String?,
                              service: GeocoderService,
                              alternativeService: GeocoderService = .undefined,
                              completionHandler: GeocodeCallback?) {
        
        // Check address string
        guard let addressString = addressString else {
            // Invalid address string --> Return error
            if !isCancelled {
                completionHandler?(nil, GeocoderError.invalidAddressString)
            }
            
            // Finish
            super.finish()
            return
        }
        
        // Valid address string --> Check service
        switch service {
        case .google, .here:
            var urlString = ""
            if service == .google {
                // Geocode using Google service
                urlString = googleGeocodingURLString
                    + "&address=\(addressString)"
                    + "&key=\(googleAPIKey ?? "")"
            }
            else {
                // Geocode using Here service
                urlString = hereGeocodingURLString
                    + "?searchtext=" + addressString
                    + "&app_id=" + (hereAppId ?? "")
                    + "&app_code=" + (hereAppCode ?? "")
            }
            
            buildRequest(with: urlString, service: service) { (results, error) in
                
                if error != nil
                    && results == nil
                    && alternativeService != .undefined
                    && !self.isCancelled {
                    // Retry with alternativeService
                    self.geocodeAddressString(addressString,
                                              service: alternativeService,
                                              completionHandler: completionHandler)
                }
                else {
                    // Return
                    DispatchQueue.main.async {
                        if !self.isCancelled {
                            completionHandler?(results, error)
                        }
                    }
                    
                    // Finish
                    super.finish()
                }
            }
        case .apple:
            // Geocode using Apple service
            if appleGeocoder == nil {
                appleGeocoder = CLGeocoder()
            }
            appleGeocoder?.geocodeAddressString(addressString, completionHandler: { (placemarks, error) in
                
                if error != nil
                    && placemarks == nil
                    && alternativeService != .undefined
                    && !self.isCancelled {
                    // Retry with alternativeService
                    self.geocodeAddressString(addressString,
                                              service: alternativeService,
                                              completionHandler: completionHandler)
                }
                else {
                    // Return
                    DispatchQueue.main.async {
                        let results = self.parseGeocodingResponse(placemarks, service: service)
                        if !self.isCancelled {
                            completionHandler?(results, error)
                        }
                    }
                    
                    // Finish
                    super.finish()
                }
            })
        default:
            break
        }
    }
    
    // MARK: REVERSE GEOCODE
    
    func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D?,
                                  service: GeocoderService,
                                  alternativeService: GeocoderService = .undefined,
                                  completionHandler: GeocodeCallback?) {
        // Check location coordinate
        guard let coordinate = coordinate, CLLocationCoordinate2DIsValid(coordinate) else {
            // Invalid location coordinate --> Return error
            if !isCancelled {
                completionHandler?(nil, GeocoderError.invalidCoordinate)
            }
            
            // Finish
            super.finish()
            return
        }
        
        // Valid location coordinate --> Check service
        switch service {
        case .google, .here:
            var urlString = ""
            if service == .google {
                // Geocode using Google service
                urlString = googleGeocodingURLString
                    + "?latlng=\(coordinate.latitude),\(coordinate.longitude)"
                    + "&key=" + (googleAPIKey ?? "")
            }
            else {
                // Geocode using Here service
                urlString = hereReverseGeocodingURLString
                    + "?mode=retrieveAddress&prox=\(coordinate.latitude),\(coordinate.longitude)"
                    + "&app_id=" + (hereAppId ?? "")
                    + "&app_code=" + (hereAppCode ?? "")
            }
            
            buildRequest(with: urlString, service: service) { (results, error) in
                
                if error != nil
                    && results == nil
                    && alternativeService != .undefined
                    && !self.isCancelled {
                    // Retry with alternativeService
                    self.reverseGeocodeCoordinate(coordinate,
                                                  service: alternativeService,
                                                  completionHandler: completionHandler)
                }
                else {
                    // Return
                    DispatchQueue.main.async {
                        if !self.isCancelled {
                            completionHandler?(results, error)
                        }
                    }
                    
                    // Finish
                    super.finish()
                }
            }
        case .apple:
            // Geocode using Apple service
            if appleGeocoder == nil {
                appleGeocoder = CLGeocoder()
            }
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            appleGeocoder?.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                
                if error != nil
                    && placemarks == nil
                    && alternativeService != .undefined
                    && !self.isCancelled {
                    // Retry with alternativeService
                    self.reverseGeocodeCoordinate(coordinate,
                                                  service: alternativeService,
                                                  completionHandler: completionHandler)
                }
                else {
                    // Return
                    DispatchQueue.main.async {
                        let results = self.parseGeocodingResponse(placemarks, service: service)
                        if !self.isCancelled {
                            completionHandler?(results, error)
                        }
                    }
                    
                    // Finish
                    super.finish()
                }
            })
        default:
            break
        }
    }
    
    // MARK: NETWORKING
    
    func buildRequest(with urlString: String,
                      service: GeocoderService,
                      completionHandler: GeocodeCallback?) {
        // Set up the URL
        guard
            let urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: urlString)
            else {
                completionHandler?(nil, GeocoderError.geocodeInternal)
                return
        }
        
        // Make the request
        geocoderTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            // Check for any errors
            guard error == nil else {
                completionHandler?(nil, error)
                return
            }
            
            // Make sure we got data
            guard let data = data else {
                completionHandler?(nil, GeocoderError.geocodeInternal)
                return
            }
            
            // Parse the result as JSON
            do {
                guard let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    completionHandler?(nil, GeocoderError.geocodeInternal)
                    return
                }
                
                // Check service
                switch service {
                case .google:
                    // Check status value
                    guard let status = result["status"] as? String, status == "OK" else {
                        completionHandler?(nil, GeocoderError.geocodeInternal)
                        return
                    }
                    
                    // Status OK --> Check response results
                    guard let locationDicts = result["results"] as? [Any] else {
                        completionHandler?(nil, GeocoderError.geocodeInternal)
                        return
                    }
                    
                    // Return results
                    let finalResults = self.parseGeocodingResponse(locationDicts, service: service)
                    completionHandler?(finalResults, nil)
                case .here:
                    // Check response results
                    guard
                        let locationDicts = (((result["Response"]
                            as? [String: Any])?["View"]
                            as? [String: Any])?["Result"] as? [Any])
                        else {
                            completionHandler?(nil, GeocoderError.geocodeInternal)
                            return
                    }
                    
                    // Return results
                    let finalResults = self.parseGeocodingResponse(locationDicts, service: service)
                    completionHandler?(finalResults, nil)
                default: break
                }
            } catch {
                completionHandler?(nil, GeocoderError.geocodeInternal)
            }
        }
        geocoderTask?.resume()
    }
    
    func parseGeocodingResponse(_ results: [Any]?, service: GeocoderService) -> [Address]? {
        guard let results = results else { return nil }
        
        var finalResults = [Address]()
        for result in results {
            if let address = Address(locationData: result, serviceType: service) {
                finalResults.append(address)
            }
        }
        return finalResults
    }
}
