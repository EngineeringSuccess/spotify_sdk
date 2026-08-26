import Flutter
import SpotifyiOS

class PlayerStateHandler: StatusHandler {
    private var appRemote: SPTAppRemote
    private let playerDelegate: PlayerDelegate

    init (appRemote: SPTAppRemote, playerDelegate: PlayerDelegate) {
        self.appRemote = appRemote
        self.playerDelegate = playerDelegate
        super.init()
    }

    func setAppRemote(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
    }

    override func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _ = super.onListen(withArguments: arguments, eventSink: events)
        playerDelegate.playerStateSink = events
        appRemote.playerAPI?.delegate = playerDelegate
        appRemote.playerAPI?.subscribe { (_, error) -> Void in
            guard error == nil else { return }
        }
        return nil
    }
}
