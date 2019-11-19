//
//  Geocoder.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 12/18/18.
//  Copyright © 2018 LMinh. All rights reserved.
//

import UIKit
import CoreLocation

/// Exposes a service for geocoding and reverse geocoding.
open class Geocoder {
    
    // MARK: - PROPERTIES
    
    /// Indicating whether the receiver is in the middle of geocoding its value.
    public var isGeocoding: Bool {
        return operationQueue.operationCount > 0
    }
    
    /// Google API key.
    public var googleAPIKey: String? = nil
    
    /// Here App Id.
    public var hereAppId: String? = nil
    
    /// Here App Code.
    public var hereAppCode: String? = nil
    
    /// Operation Queue.
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Geocoding Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    // MARK: SINGLETON
    
    /// Get shared instance.
    public static let shared = Geocoder()
    
    // MARK: GEOCODING
    
    /// Submits a forward-geocoding request using the specified string.
    /// After initiating a forward-geocoding request, do not attempt to initiate another forward- or reverse-geocoding request.
    /// Geocoding requests are rate-limited for each app, so making too many requests in a
    /// short period of time may cause some of the requests to fail.
    /// When the maximum rate is exceeded, the geocoder passes an error object to your completion handler.
    ///
    /// - Parameters:
    ///   - addressString: The string describing the location you want to look up.
    ///   - service: The service API used to geocode.
    ///   - alternativeService: The service API will be used if service API failed. LMGeocoderServiceUndefined means no alternative.
    ///   - completionHandler: The callback to invoke with the geocode results. The callback will be invoked asynchronously from the main thread.
    public func geocodeAddressString(_ addressString: String,
                                     service: GeocoderService,
                                     alternativeService: GeocoderService = .undefined,
                                     completionHandler: GeocodeCallback?) {
        operationQueue.cancelAllOperations()
        let operation = GeocodingOperation(addressString: addressString,
                                           isReverseGeocoding: false,
                                           service: service,
                                           alternativeService:alternativeService,
                                           googleAPIKey: googleAPIKey,
                                           hereAppId: hereAppId,
                                           hereAppCode: hereAppCode,
                                           completionHandler: completionHandler)
        operationQueue.addOperation(operation)
    }
    
    /// Submits a reverse-geocoding request for the specified coordinate.
    /// After initiating a reverse-geocoding request, do not attempt to initiate another reverse- or forward-geocoding request.
    /// Geocoding requests are rate-limited for each app, so making too many requests in a
    /// short period of time may cause some of the requests to fail.
    /// When the maximum rate is exceeded, the geocoder passes an error object to your completion handler.
    ///
    /// - Parameters:
    ///   - coordinate: The coordinate to look up.
    ///   - service: The service API used to reverse geocode.
    ///   - alternativeService: The service API will be used if service API failed. LMGeocoderServiceUndefined means no alternative.
    ///   - completionHandler: The callback to invoke with the reverse geocode results.The callback will be invoked asynchronously from the main thread.
    public func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D,
                                         service: GeocoderService,
                                         alternativeService: GeocoderService = .undefined,
                                         completionHandler: GeocodeCallback?) {
        operationQueue.cancelAllOperations()
        let operation = GeocodingOperation(coordinate: coordinate,
                                           isReverseGeocoding: true,
                                           service: service,
                                           alternativeService:alternativeService,
                                           googleAPIKey: googleAPIKey,
                                           hereAppId: hereAppId,
                                           hereAppCode: hereAppCode,
                                           completionHandler: completionHandler)
        operationQueue.addOperation(operation)
    }
    
    /// Cancels a pending geocoding request.
    public func cancelGeocode() {
        operationQueue.cancelAllOperations()
    }
}
