import Combine
import CoreLocation

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var coordinate: CLLocationCoordinate2D?
    @Published var cityName:   String = "your area"
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    private let manager  = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate        = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authStatus = manager.authorizationStatus
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }
    func startUpdating()     { manager.requestLocation() }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        coordinate = loc.coordinate
        geocoder.reverseGeocodeLocation(loc) { [weak self] marks, _ in
            guard let place = marks?.first else { return }
            let city  = place.locality ?? place.subAdministrativeArea ?? "your area"
            let state = place.administrativeArea ?? ""
            DispatchQueue.main.async { self?.cityName = state.isEmpty ? city : "\(city), \(state)" }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways { startUpdating() }
    }
}
