//
//  ViewController.swift
//  Subul
//
//  Created by Tuğrulhan Çınar on 25.09.2024.
//

import UIKit
import MapKit
import CoreLocation

class SubulViewController: UIViewController {

    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }


}

// MARK: - CLLocationManagerDelegate

extension SubulViewController: CLLocationManagerDelegate {
    // Haritayı belirli bir lokasyona odakla
    func centerMapOnLocation(location: CLLocation, regionRadius: CLLocationDistance = 1000) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    // Konum güncellemesi aldığında haritayı güncelle
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            centerMapOnLocation(location: location)
        }
    }
}
