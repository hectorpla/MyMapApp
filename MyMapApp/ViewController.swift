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
            do {
                // clean up
                self.cleanUpLocation()
                
                response!.mapItems.forEach({ (item) in
                    let annotation = MKPointAnnotation()
                    
                    print(item.placemark)
                    annotation.title = item.name
                    annotation.subtitle = item.placemark.title // text displayed when tapped
                    annotation.coordinate = item.placemark.coordinate
                    self.searchedAnnotations.append(annotation)
                })
                
                self.myMapView.addAnnotations(self.searchedAnnotations)
                // TODO: handle selection and deselection
            }
        }
    }
    
    func cleanUpLocation() {
        myMapView.removeAnnotations(self.searchedAnnotations)
        searchedAnnotations.removeAll()
    }
    
    // Mark: on tap behavior
    @IBAction func handleTapInMap(_ sender: UITapGestureRecognizer) {
        // check if the annotation is tapped
        cleanUpLocation()
    }
    
    
    // Mark: custom annotation view: animation
    
    
    // TEMP: user location functionality beyond initial retrieval omitted
}

