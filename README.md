# LMGeocoderSwift
LMGeocoderSwift is a simple wrapper for geocoding and reverse geocoding, using both Google Geocoding API and Apple iOS Geocoding Framework.

[![CI Status](https://img.shields.io/travis/LMinh/LMGeocoderSwift.svg?style=flat)](https://travis-ci.org/LMinh/LMGeocoderSwift)
[![Version](https://img.shields.io/cocoapods/v/LMGeocoderSwift.svg?style=flat)](https://cocoapods.org/pods/LMGeocoderSwift)
[![License](https://img.shields.io/cocoapods/l/LMGeocoderSwift.svg?style=flat)](https://cocoapods.org/pods/LMGeocoderSwift)
[![Platform](https://img.shields.io/cocoapods/p/LMGeocoderSwift.svg?style=flat)](https://cocoapods.org/pods/LMGeocoderSwift)

![](https://raw.github.com/lminhtm/LMGeocoder/master/Screenshots/screenshot.png)

## Features
* Wrapper for Geocoding and Reverse geocoding with blocked-based coding.
* Use both Google Geocoding API and Apple iOS Geocoding Framework.

## Requirements
* iOS 8.0 or higher
* Swift 5.0

## Installation
LMGeocoderSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'LMGeocoderSwift'
```

## Objective-C Version
https://github.com/lminhtm/LMGeocoder

## Usage
#### Geocoding
```Swift
Geocoder.shared.geocodeAddressString(addressString, service: .apple, alternativeService: .google) { (results, error) in
                
    // Update UI
    if let address = results?.first, error == nil {
        DispatchQueue.main.async {
            self.coordinateLabel.text = "(\(address.coordinate?.latitude ?? 0), \(address.coordinate?.longitude ?? 0))"
        }
    }
}
```

#### Reverse Geocoding
```Swift
Geocoder.shared.reverseGeocodeCoordinate(coordinate, service: .apple, alternativeService: .google) { (results, error) in
                
    // Update UI
    if let address = results?.first, error == nil {
        DispatchQueue.main.async {
            self.addressLabel.text = address.formattedAddress ?? "-"
        }
    }
}
```

#### Cancel Geocode
```Swift
Geocoder.shared.cancelGeocode()
```

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## License
LMGeocoderSwift is available under the MIT license. See the LICENSE file for more info.

## Author
Minh Nguyen
* https://github.com/lminhtm
* lminhtm@gmail.com
