import Foundation
import CoreLocation

final class SAMHSAService {

    private let endpoint = "https://findtreatment.gov/locator/exportsAsJson/v2"

    func fetchResources(near location: CLLocationCoordinate2D, radiusMiles: Double = 25) async -> [LocalResource] {
        let meters = radiusMiles * 1609.34
        var c = URLComponents(string: endpoint)!
        c.queryItems = [
            .init(name: "sAddr",      value: "\"\(location.latitude),\(location.longitude)\""),
            .init(name: "limitType",  value: "2"),
            .init(name: "limitValue", value: "\(meters)"),
            .init(name: "sType",      value: "mh"),
            .init(name: "pageSize",   value: "20"),
            .init(name: "page",       value: "1"),
            .init(name: "sort",       value: "0"),
        ]
        guard let url = c.url else { return fallback() }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return fallback() }
            return parse(data: data)
        } catch {
            if radiusMiles < 50 { return await fetchResources(near: location, radiusMiles: 50) }
            return fallback()
        }
    }

    private func parse(data: Data) -> [LocalResource] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return fallback() }
        let rows: [[String: Any]]
        if let a = json as? [[String: Any]] { rows = a }
        else if let d = json as? [String: Any], let r = d["rows"] as? [[String: Any]] { rows = r }
        else { return fallback() }

        var results: [LocalResource] = []
        for row in rows.prefix(20) {
            guard let name  = row["name1"] as? String, !name.isEmpty,
                  let phone = row["phone"] as? String, !phone.isEmpty else { continue }
            let address = [row["street1"], row["city"], row["state"], row["zip"]]
                .compactMap { $0 as? String }.filter { !$0.isEmpty }.joined(separator: ", ")
            results.append(LocalResource(name: name.trimmingCharacters(in: .whitespaces),
                                         phone: phone.trimmingCharacters(in: .whitespaces),
                                         address: address))
            if results.count == 5 { break }
        }
        return results.isEmpty ? fallback() : results
    }

    private func fallback() -> [LocalResource] {[
        LocalResource(name: "SAMHSA National Helpline", phone: "1-800-662-4357",
                      address: "Free, confidential, 24/7 — anywhere in the US"),
        LocalResource(name: "Crisis Text Line", phone: "Text HOME to 741741",
                      address: "Free, 24/7 text-based crisis support"),
    ]}
}
