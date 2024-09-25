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
    var selectedTransportType: MKDirectionsTransportType = .automobile
    var currentRoute: MKPolyline?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addressButtonTapped))
        
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        view.addSubview(mapView)
        
        mapView.showsUserLocation = true

        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
    
    @objc func addressButtonTapped() {
           let alertController = UIAlertController(title: "address", message: "\n\n\n\n\n", preferredStyle: .alert)
           
           alertController.addTextField { (textField) in
               textField.placeholder = "Start address"
           }
           
           alertController.addTextField { (textField) in
               textField.placeholder = "destination address"
           }
           
           let segmentedControl = UISegmentedControl(items: ["Walking", "automobile"])
           segmentedControl.frame = CGRect(x: 10, y: 80, width: 250, height: 30)
           segmentedControl.selectedSegmentIndex = 1 // Varsayılan olarak "Araba" seçili
           
           alertController.view.addSubview(segmentedControl)
           
           let submitAction = UIAlertAction(title: "Ok", style: .default) { [unowned self] _ in
               let startAddress = alertController.textFields?[0].text
               let endAddress = alertController.textFields?[1].text
               
               if startAddress == nil || startAddress == "" || endAddress == nil || endAddress == "" {
                   showErrorAlet(msg: "Address section cannot be empty")
                   return
               }
               if segmentedControl.selectedSegmentIndex == 0 {
                   self.selectedTransportType = .walking // Yaya
               } else {
                   self.selectedTransportType = .automobile // Araba
               }
               
               if let start = startAddress, let end = endAddress {
                   self.calculateRoute(startAddress: start, endAddress: end)
               }
           }
           
           let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
           
           alertController.addAction(submitAction)
           alertController.addAction(cancelAction)
           
           present(alertController, animated: true, completion: nil)
       }
    
    func calculateRoute(startAddress: String, endAddress: String) {

        mapView.removeAnnotations(mapView.annotations)
        
        getCoordinateFrom(address: startAddress) { (startCoordinate) in
            self.getCoordinateFrom(address: endAddress) { (endCoordinate) in
                self.addAnnotationToMap(coordinate: startCoordinate, title: "start")
                self.addAnnotationToMap(coordinate: endCoordinate, title: "destination")
                
                self.showRouteOnMap(pickupCoordinate: startCoordinate, destinationCoordinate: endCoordinate, transportType: self.selectedTransportType)
            }
        }
    }
    
    func getCoordinateFrom(address: String, completion: @escaping(CLLocationCoordinate2D) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let placemark = placemarks?.first, let location = placemark.location {
                completion(location.coordinate)
            }
        }
    }
    
    func addAnnotationToMap(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
    
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, transportType: MKDirectionsTransportType) {
        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: pickupPlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = transportType
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let response = response else {
                print("Rota hesaplanamadı: \(String(describing: error))")
                return
            }
            
            // Önceki rotayı kaldır
                    if let existingRoute = self.currentRoute {
                        self.mapView.removeOverlay(existingRoute)
                    }
            
            let route = response.routes[0]
            self.currentRoute = route.polyline
            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
    
    }

extension SubulViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            
            polylineRenderer.strokeColor = (overlay as! MKPolyline).title == "Walking" ? UIColor.red : UIColor.blue
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "CustomPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let image = annotation.title == "start" ? CustomIcon.startIcon.getImage() : CustomIcon.finishICon.getImage()
            
            annotationView?.image = image.resizeImage(to: CGSize(width: 15, height: 15))
            
            let calloutButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = calloutButton
        } else {
            annotationView?.annotation = annotation
        }
           return annotationView
       }
    
}

extension UIImage {

    func resizeImage(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return resizedImage
    }
}

enum CustomIcon: String {
    case startIcon = "start"
    case finishICon = "finish"
    
    func getImage() -> UIImage {
        
        return UIImage(named: self.rawValue)!
    }
}


extension SubulViewController {
    
    func showErrorAlet(_ title: String? = "Error", msg: String, cancelButtonMsg: String = "Ok") {
        
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelButtonMsg, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
