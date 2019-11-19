//
//  ViewController.swift
//  LMGeocoderSwift
//
//  Created by LMinh on 03/02/2019.
//  Copyright (c) 2019 LMinh. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import LMGeocoderSwift

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var latitudeView: UIView!
    @IBOutlet weak var longitudeView: UIView!
    @IBOutlet weak var addressView: UIView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    // MARK: VIEW LIFECYCLE
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // You can set your google API key here
        Geocoder.shared.googleAPIKey = "AIzaSyCsJgBk7TOm5Rw2mGMh6QWmsC9H9_g8odI"
        
        // Start getting current location
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 20
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        // Configure UI
        self.configureUI()
    }
    
    func configureUI() {
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        // Black background
        self.latitudeView.layer.cornerRadius = 5
        self.longitudeView.layer.cornerRadius = 5
        self.addressView.layer.cornerRadius = 5
        self.latitudeView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.longitudeView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.addressView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Show camera on real device for nice effect
        let hasCamera = AVCaptureDevice.devices().count > 0
        if hasCamera {
            let session = AVCaptureSession();
            session.sessionPreset = AVCaptureSession.Preset.high;
            
            let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            captureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
            captureVideoPreviewLayer.frame = self.backgroundImageView.bounds;
            self.backgroundImageView.layer.addSublayer(captureVideoPreviewLayer)
            
            let device = AVCaptureDevice.default(for: AVMediaType.video);
            do {
                let input = try AVCaptureDeviceInput.init(device: device!)
                session.addInput(input)
                session.startRunning()
            }
            catch {
            }
        }
        else {
            self.backgroundImageView.image = UIImage(named: "background")
        }
    }
    
    // MARK: LOCATION MANAGER DELEGATE
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let coordinate = locations.last?.coordinate else { return }
        
        // Update UI
        self.latitudeLabel.text = String(format: "%f", coordinate.latitude)
        self.longitudeLabel.text = String(format: "%f", coordinate.longitude)
        
        // Start to reverse geocode
        print("Start to reverse geocode with \(coordinate.latitude), \(coordinate.longitude)")
        Geocoder.shared.cancelGeocode()
        Geocoder.shared.reverseGeocodeCoordinate(coordinate, service: .google, alternativeService: .apple) { (results, error) in
            
            // Update UI
            if let address = results?.first, error == nil {
                print("Reverse geocode result for \(coordinate.latitude), \(coordinate.longitude): \n\(address.formattedAddress ?? "-")\n");
                DispatchQueue.main.async {
                    self.addressLabel.text = address.formattedAddress ?? "-"
                }
            }
        }
    }
}

