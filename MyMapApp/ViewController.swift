//
//  ViewController.swift
//  MyMapApp
//
//  Created by Hector Lueng on 4/5/18.
//  Copyright © 2018 USC. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController, UISearchBarDelegate, MKMapViewDelegate,
                    CLLocationManagerDelegate {

    @IBOutlet weak var destSearchBar: UISearchBar!
    @IBOutlet weak var myMapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var currentLocationCoordinate: CLLocationCoordinate2D!
    var searchedAnnotations = [MKAnnotation]()
    var tappedAnnotation: MKAnnotation?
    
    var destination: MKMapItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        destSearchBar.delegate = self
        destSearchBar.placeholder = "Destination"
        
        myMapView.delegate = self
        myMapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark: change the location in map if current location changes
    
    
    // Mark: do necessary notification when location updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            print("didn't find the current location")
            return
        }
        currentLocationCoordinate = newLocation.coordinate
        let region = MKCoordinateRegion(center: currentLocationCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//        myMapView.setCenter(currentLocationCoordinate, animated: true)
        myMapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation() // temperary
    }
    
    // Mark: search for destination
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let destText = destSearchBar.text!
        let localSearchRequest = MKLocalSearchRequest()
        
        localSearchRequest.naturalLanguageQuery = destText
        localSearchRequest.region = myMapView.region // set it exactly as the displayed
        
        let localSearch = MKLocalSearch(request: localSearchRequest)
        
        localSearch.start { (response, error) in
            if error != nil {
                print(error!)
                return
            }
            self.displaySearchedItems(response!.mapItems)
        }
    }
    
    // Mark: handle search response
    func displaySearchedItems(_ items: [MKMapItem]) {
        do {
            // clean up
            self.cleanUpLocation()
            
            items.forEach({ (item) in
                let annotation = MKPointAnnotation()
                
//                print(item.placemark)
                annotation.title = item.name
                annotation.subtitle = item.placemark.title // text displayed when tapped
                annotation.coordinate = item.placemark.coordinate
                self.searchedAnnotations.append(annotation)
            })
            
            self.myMapView.addAnnotations(self.searchedAnnotations)
            // TODO: handle selection and deselection
        }
    }
    
    // Mark: custom annotation view: animation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "destAnnot"
        var annotationView = myMapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            let annotationPinView = MKPinAnnotationView()
            annotationPinView.pinTintColor = MKPinAnnotationView.purplePinColor()
            annotationPinView.animatesDrop = true
            annotationPinView.canShowCallout = true
            annotationPinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = annotationPinView
        }
        
        return annotationView
    }
    
    func cleanUpLocation() {
        myMapView.removeAnnotations(self.searchedAnnotations)
        searchedAnnotations.removeAll()
    }
    
    // Mark: pop up view for annotation
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // check
        getDirection(to: MKMapItem(placemark: MKPlacemark(coordinate: (view.annotation?.coordinate)!)))
    }
    
    // Mark: long press behavior
    @IBAction func handleLongPressInMap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: myMapView)
            let tappedCoordinate = myMapView.convert(location, toCoordinateFrom: myMapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = tappedCoordinate
            annotation.title = "selected location"
            annotation.subtitle = "..."
            tappedAnnotation = annotation
            myMapView.addAnnotation(annotation)
        }
    }
    
    // Mark: on tap behavior
    @IBAction func handleTapInMap(_ gestureRecognizer: UITapGestureRecognizer) {
        if tappedAnnotation != nil {
            myMapView.removeAnnotation(tappedAnnotation!)
            tappedAnnotation = nil
        }
    }
    
    // TEMP: user location functionality beyond initial retrieval omitted
}

extension ViewController {
    // Mark: direction
    func getDirection(to dest: MKMapItem?) {
        if dest == nil {
            print("geting directions: no destination selected")
        }
        
        let source = MKMapItem.forCurrentLocation()
        
        print("geting directions: source -> \(source)")
        
        let directionsRequest = MKDirectionsRequest()
        directionsRequest.source = source
        directionsRequest.destination = dest
        directionsRequest.transportType = .walking
        
        MKDirections(request: directionsRequest)
                .calculate { (response, error) in
            if error != nil {
                print("geting directions Error: \(error)")
                return
            }
            self.drawSingleRoute(response!.routes.first) // check later
        }
    }
    
    // MARK: customize overlay style
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer()
            renderer.strokeColor = UIColor.cyan
            renderer.lineWidth = 5
            return renderer
        } else {
            return MKOverlayRenderer()
        }
    }
    
    // MARK: draw direction
    func drawSingleRoute(_ route: MKRoute?) {
        if route == nil {
            print("drawSingleRoute: unexpected route is nil")
            return
        }
        print("drawSingleRoute:", route!)
        
        // test
        myMapView.addOverlays([route!.polyline], level: .aboveLabels)
    }
}
