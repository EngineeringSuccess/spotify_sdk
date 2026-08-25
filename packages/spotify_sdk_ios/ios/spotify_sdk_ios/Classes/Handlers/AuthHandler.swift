import Flutter
import SpotifyiOS

class AuthHandler: NSObject {
    private unowned let remoteManager: RemoteManager
    private var sessionManager: SPTSessionManager?

    init(remoteManager: RemoteManager) {
        self.remoteManager = remoteManager
        super.init()
    }

    public func connectToSpotify(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let swiftArguments = call.arguments as? [String: Any],
              let clientID = swiftArguments[SpotifySdkConstants.paramClientId] as? String,
              !clientID.isEmpty else {
            result(SpotifyErrorMapper.argumentError("Client ID is not set"))
            return
        }

        guard let url = swiftArguments[SpotifySdkConstants.paramRedirectUrl] as? String,
              !url.isEmpty else {
            result(SpotifyErrorMapper.argumentError("Redirect URL is not set"))
            return
        }

        remoteManager.connectionStatusHandler?.connectionResult = result
        let accessToken: String? = swiftArguments[SpotifySdkConstants.paramAccessToken] as? String
        let spotifyUri: String = swiftArguments[SpotifySdkConstants.paramSpotifyUri] as? String ?? ""

        do {
            try connectToSpotifyInternal(clientId: clientID, redirectURL: url, accessToken: accessToken, spotifyUri: spotifyUri, asRadio: swiftArguments[SpotifySdkConstants.paramAsRadio] as? Bool, additionalScopes: swiftArguments[SpotifySdkConstants.scope] as? String)
        }
        catch SpotifyError.redirectURLInvalid {
            result(SpotifyErrorMapper.makeError(code: "errorConnecting", message: "Redirect URL is not set or has invalid format"))
        }
        catch {
            result(SpotifyErrorMapper.makeError(code: "CouldNotFindSpotifyApp", message: "The Spotify app is not installed on the device"))
        }
    }

    public func getAccessTokenOrSwapToken(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let swiftArguments = call.arguments as? [String: Any],
              let clientID = swiftArguments[SpotifySdkConstants.paramClientId] as? String,
              let url = swiftArguments[SpotifySdkConstants.paramRedirectUrl] as? String else {
            result(SpotifyErrorMapper.argumentError("One or more arguments are missing"))
            return
        }
        guard let redirectURL = URL(string: url) else {
            result(SpotifyErrorMapper.makeError(code: "errorConnecting", message: "Redirect URL is not set or has invalid format"))
            return
        }

        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        if let tokenSwapURL = swiftArguments["tokenSwapURL"] as? String,
           let tokenRefreshURL = swiftArguments["tokenRefreshURL"] as? String {
            configuration.tokenSwapURL = URL(string: tokenSwapURL)
            configuration.tokenRefreshURL = URL(string: tokenRefreshURL)
        }

        remoteManager.connectionStatusHandler?.tokenResult = result
        sessionManager = SPTSessionManager(configuration: configuration, delegate: self)

        var requestedScopes: SPTScope = []
        let scopes = (swiftArguments[SpotifySdkConstants.scope] as? String)?.components(separatedBy: ",") ?? []
        for scope in scopes.map({ $0.trimmingCharacters(in: .whitespaces) }) {
            switch scope {
            case "user-read-playback-state": requestedScopes.insert(.userReadPlaybackState)
            case "user-modify-playback-state": requestedScopes.insert(.userModifyPlaybackState)
            case "user-read-currently-playing": requestedScopes.insert(.userReadCurrentlyPlaying)
            case "user-read-recently-played": requestedScopes.insert(.userReadRecentlyPlayed)
            case "app-remote-control": requestedScopes.insert(.appRemoteControl)
            case "playlist-read-private": requestedScopes.insert(.playlistReadPrivate)
            case "playlist-read-collaborative": requestedScopes.insert(.playlistReadCollaborative)
            case "user-library-read": requestedScopes.insert(.userLibraryRead)
            default: break
            }
        }

        let hasTokenSwap = swiftArguments["tokenSwapURL"] != nil
        sessionManager?.initiateSession(with: requestedScopes, options: hasTokenSwap ? .default : .clientOnly, campaign: nil)
    }

    public func handleOpenURL(_ application: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        guard let sessionManager = sessionManager else { return false }
        sessionManager.application(application, open: url, options: options)
        return true
    }

    public func isSpotifyInstalled(result: @escaping FlutterResult) {
        result(UIApplication.shared.canOpenURL(URL(string: "spotify:")!))
    }

    public func disconnect(result: @escaping FlutterResult) {
        remoteManager.appRemote?.disconnect()
        result(true)
    }

    private func connectToSpotifyInternal(clientId: String, redirectURL: String, accessToken: String? = nil, spotifyUri: String = "", asRadio: Bool? = false, additionalScopes: String? = nil) throws {
        guard let redirectURL = URL(string: redirectURL) else {
            throw SpotifyError.redirectURLInvalid
        }

        let configuration = SPTConfiguration(clientID: clientId, redirectURL: redirectURL)
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .none)
        remoteManager.appRemote = appRemote

        appRemote.delegate = remoteManager.connectionStatusHandler
        appRemote.connectionParameters.accessToken = accessToken

        let playerDelegate = PlayerDelegate()
        if remoteManager.playerStateHandler == nil {
            remoteManager.playerStateHandler = PlayerStateHandler(appRemote: appRemote, playerDelegate: playerDelegate)
            RemoteManager.playerStateChannel?.setStreamHandler(remoteManager.playerStateHandler)
        }
        if remoteManager.playerContextHandler == nil {
            remoteManager.playerContextHandler = PlayerContextHandler(appRemote: appRemote, playerDelegate: playerDelegate)
            RemoteManager.playerContextChannel?.setStreamHandler(remoteManager.playerContextHandler)
        }
        if remoteManager.capabilitiesHandler == nil {
            remoteManager.capabilitiesHandler = CapabilitiesHandler()
            RemoteManager.capabilitiesChannel?.setStreamHandler(remoteManager.capabilitiesHandler)
        }
        remoteManager.capabilitiesHandler?.setAppRemote(appRemote)

        var scopes: [String]?
        if let additionalScopes = additionalScopes {
            scopes = additionalScopes.components(separatedBy: ",")
        }

        if accessToken != nil {
            appRemote.connect()
        } else {
            appRemote.authorizeAndPlayURI(spotifyUri, asRadio: asRadio ?? false, additionalScopes: scopes) { success in
                if (!success) {
                    self.remoteManager.connectionStatusHandler?.connectionResult?(FlutterError(code: "spotifyNotInstalled", message: "Spotify app is not installed", details: nil))
                    self.remoteManager.connectionStatusHandler?.tokenResult?(FlutterError(code: "spotifyNotInstalled", message: "Spotify app is not installed", details: nil))
                    self.remoteManager.connectionStatusHandler?.connectionResult = nil
                    self.remoteManager.connectionStatusHandler?.tokenResult = nil
                }
            }
        }
    }
}

extension AuthHandler: SPTSessionManagerDelegate {
    public func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        remoteManager.connectionStatusHandler?.tokenResult?([
            "accessToken": session.accessToken,
            "refreshToken": session.refreshToken,
            "expiresAt": session.expirationDate.timeIntervalSince1970
        ])
        remoteManager.connectionStatusHandler?.tokenResult = nil
        sessionManager = nil
    }

    public func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        remoteManager.connectionStatusHandler?.tokenResult?(FlutterError(code: "authenticationTokenError", message: error.localizedDescription, details: nil))
        remoteManager.connectionStatusHandler?.tokenResult = nil
        sessionManager = nil
    }

    public func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        remoteManager.appRemote?.connectionParameters.accessToken = session.accessToken
    }
}
