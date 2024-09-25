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
      var startAddressField: UITextField!
      var destinationAddressField: UITextField!
      var calculateRouteButton: UIButton!
      
      override func viewDidLoad() {
          super.viewDidLoad()
          
          // MapView oluştur ve ekrana yerleştir
          mapView = MKMapView(frame: CGRect(x: 0, y: 200, width: view.frame.size.width, height: view.frame.size.height - 200))
          view.addSubview(mapView)
          
          // Kullanıcının konumunu göster
          mapView.showsUserLocation = true
          mapView.delegate = self
          
          // Konum yöneticisini başlat
          locationManager = CLLocationManager()
          locationManager.requestWhenInUseAuthorization()

          // Başlangıç adresi için TextField
          startAddressField = UITextField(frame: CGRect(x: 20, y: 50, width: view.frame.size.width - 40, height: 40))
          startAddressField.placeholder = "Başlangıç adresi"
          startAddressField.borderStyle = .roundedRect
          view.addSubview(startAddressField)
          
          // Varış adresi için TextField
          destinationAddressField = UITextField(frame: CGRect(x: 20, y: 100, width: view.frame.size.width - 40, height: 40))
          destinationAddressField.placeholder = "Varış adresi"
          destinationAddressField.borderStyle = .roundedRect
          view.addSubview(destinationAddressField)
          
          // Rota hesapla butonu
          calculateRouteButton = UIButton(frame: CGRect(x: 20, y: 150, width: view.frame.size.width - 40, height: 40))
          calculateRouteButton.setTitle("Rota Hesapla", for: .normal)
          calculateRouteButton.backgroundColor = .blue
          calculateRouteButton.addTarget(self, action: #selector(calculateRoute), for: .touchUpInside)
          view.addSubview(calculateRouteButton)
      }
      
      @objc func calculateRoute() {
          // Girilen adreslerin koordinatlarını al
          guard let startAddress = startAddressField.text, let destinationAddress = destinationAddressField.text else { return }
          // Mevcut işaretçileri kaldır
          mapView.removeAnnotations(mapView.annotations)
          getCoordinateFrom(address: startAddress) { (startCoordinate) in
              self.getCoordinateFrom(address: destinationAddress) { (destinationCoordinate) in
                  // Başlangıç ve bitiş noktalarına işaretçi ekle

                  self.addAnnotationToMap(coordinate: startCoordinate, title: "Başlangıç")
                  self.addAnnotationToMap(coordinate: destinationCoordinate, title: "Bitiş")
                  
                  // Yaya rotasını göster
                  self.showRouteOnMap(pickupCoordinate: startCoordinate, destinationCoordinate: destinationCoordinate, transportType: .walking)
                  
                  // Araç rotasını göster
                  self.showRouteOnMap(pickupCoordinate: startCoordinate, destinationCoordinate: destinationCoordinate, transportType: .automobile)
              }
          }
      }
      
      // Adresten koordinat al
      func getCoordinateFrom(address: String, completion: @escaping(CLLocationCoordinate2D) -> Void) {
          let geocoder = CLGeocoder()
          geocoder.geocodeAddressString(address) { (placemarks, error) in
              if let placemark = placemarks?.first, let location = placemark.location {
                  completion(location.coordinate)
              }
          }
      }
      
    // Koordinata işaretçi ekle
    func addAnnotationToMap(coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
    
      // Rota oluştur ve haritada göster
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
              
              let route = response.routes[0]
                            
              self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
              self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
          }
        }
    
    }

extension SubulViewController: MKMapViewDelegate {
    // Rota çizgilerini haritada göster
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            
            // Yaya rotası kırmızı, araç rotası mavi olacak
            polylineRenderer.strokeColor = (overlay as! MKPolyline).title == "Walking" ? UIColor.red : UIColor.blue
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    
    // İşaretçileri özelleştir ve özel ikon ekle
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "CustomPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            let image = annotation.title == "Başlangıç" ? CustomIcon.startIcon.getImage() : CustomIcon.finishICon.getImage()
            
            annotationView?.image = image.resizeImage(to: CGSize(width: 15, height: 15))
            
            // İsteğe bağlı olarak çağrı kartına bir buton ekle
            let calloutButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = calloutButton
        } else {
            annotationView?.annotation = annotation
        }
           return annotationView
       }
    
}

extension UIImage {
    // Görseli yeniden boyutlandırma fonksiyonu
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
