import Flutter
import SpotifyiOS
import UIKit

public struct SpotifyErrorMapper {
    public static func makeError(code: String, message: String, details: Any? = nil) -> FlutterError {
        return FlutterError(code: code, message: message, details: details)
    }

    public static func nativeDetails(_ error: Error?, operation: String, remote: SPTAppRemote? = nil) -> [String: Any] {
        var chain: [[String: Any]] = []
        var current = error as NSError?
        var visited = Set<ObjectIdentifier>()
        while let native = current, chain.count < 8 {
            guard visited.insert(ObjectIdentifier(native)).inserted else { break }
            var entry: [String: Any] = ["domain": native.domain, "code": native.code]
            if native.localizedDescription.contains("wamp.error.not_authorized") ||
                native.localizedFailureReason?.contains("wamp.error.not_authorized") == true {
                entry["reason"] = "wamp.error.not_authorized"
            }
            chain.append(entry)
            current = native.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        var details: [String: Any] = [
            "operation": operation,
            "app_state": UIApplication.shared.applicationState.rawValue,
            "native_errors": chain,
            "authorization_callback_count": RemoteManager.shared.connectionStatusHandler?.authorizationCallbackCount ?? 0,
            "authorization_callback_sources": RemoteManager.shared.connectionStatusHandler?.authorizationCallbackSources ?? []
        ]
        if let remote = remote {
            details["remote_id"] = String(describing: ObjectIdentifier(remote))
            details["is_current_remote"] = RemoteManager.shared.appRemote === remote
            details["remote_connected"] = remote.isConnected
            details["has_player_api"] = remote.playerAPI != nil
        }
        return details
    }

    public static func notConnectedError() -> FlutterError {
        return FlutterError(code: "spotifyAppRemoteNull", message: "spotifyAppRemote is null or disconnected", details: nil)
    }

    public static func argumentError(_ message: String = "Argument Error") -> FlutterError {
        return FlutterError(code: "Argument Error", message: message, details: nil)
    }
}
