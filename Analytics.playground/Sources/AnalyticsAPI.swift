import Foundation

public enum AnalyticsAPI {
    public static func send(name: String, metadata: [String: Any]) {
        var log = ""
        log += "Event: \(name)"
        for (k, v) in metadata {
            log += "\t"
            log += "\(k): \(String(describing: v))"
        }
        print(log)
    }
}

