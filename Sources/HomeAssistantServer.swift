import Foundation
import Network

class HomeAssistantServer {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.macos-audio-bridge.server")
    private let systemVolume: SystemVolume?
    private var port: UInt16
    
    init() {
        self.systemVolume = SystemVolume()
        self.port = UInt16(UserDefaults.standard.integer(forKey: "api_port"))
        if self.port == 0 {
            self.port = 8888
            UserDefaults.standard.set(8888, forKey: "api_port")
        }
    }
    
    func start() {
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("✅ Server listening on port \(self.port)")
                case .failed(let error):
                    print("❌ Server failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("❌ Failed to start server: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        print("🛑 Server stopped")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        
        receiveRequest(connection: connection)
    }
    
    private func receiveRequest(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let error = error {
                print("❌ Receive error: \(error)")
                connection.cancel()
                return
            }
            
            if let data = data, !data.isEmpty {
                self?.processRequest(data: data, connection: connection)
            }
            
            if isComplete {
                connection.cancel()
            }
        }
    }
    
    private func processRequest(data: Data, connection: NWConnection) {
        guard let request = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, status: 400, body: ["error": "Invalid request"])
            return
        }
        
        // Parse HTTP request
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendResponse(connection: connection, status: 400, body: ["error": "Invalid request"])
            return
        }
        
        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            sendResponse(connection: connection, status: 400, body: ["error": "Invalid request"])
            return
        }
        
        let method = components[0]
        let path = components[1]
        
        // Extract body for POST requests
        var body: [String: Any]? = nil
        if method == "POST" {
            if let bodyStart = request.range(of: "\r\n\r\n") {
                let bodyString = String(request[bodyStart.upperBound...])
                if let bodyData = bodyString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
                    body = json
                }
            }
        }
        
        // Route the request
        handleRoute(method: method, path: path, body: body, connection: connection)
    }
    
    private func handleRoute(method: String, path: String, body: [String: Any]?, connection: NWConnection) {
        guard systemVolume != nil else {
            sendResponse(connection: connection, status: 500, body: ["error": "Audio system not available"])
            return
        }
        
        switch (method, path) {
        // Volume endpoints
        case ("GET", "/api/status"):
            handleGetStatus(connection: connection)
        case ("GET", "/api/volume"):
            handleGetVolume(connection: connection)
        case ("POST", "/api/volume"):
            handleSetVolume(body: body, connection: connection)
        case ("GET", "/api/mute"):
            handleGetMute(connection: connection)
        case ("POST", "/api/mute"):
            handleSetMute(body: body, connection: connection)
            
        // Media control endpoints
        case ("POST", "/api/media/play_pause"):
            handleMediaPlayPause(connection: connection)
        case ("POST", "/api/media/play"):
            handleMediaPlay(connection: connection)
        case ("POST", "/api/media/pause"):
            handleMediaPause(connection: connection)
        case ("POST", "/api/media/stop"):
            handleMediaStop(connection: connection)
        case ("POST", "/api/media/next"):
            handleMediaNext(connection: connection)
        case ("POST", "/api/media/previous"):
            handleMediaPrevious(connection: connection)
        case ("GET", "/api/media/state"):
            handleGetMediaState(connection: connection)
        case ("GET", "/api/media/info"):
            handleGetMediaInfo(connection: connection)
        case ("POST", "/api/media/seek"):
            handleMediaSeek(body: body, connection: connection)
        case ("POST", "/api/media/shuffle"):
            handleMediaShuffle(connection: connection)
        case ("POST", "/api/media/repeat"):
            handleMediaRepeat(connection: connection)
            
        // Audio device endpoints
        case ("GET", "/api/audio/devices"):
            handleGetAudioDevices(connection: connection)
        case ("GET", "/api/audio/output"):
            handleGetOutputDevice(connection: connection)
        case ("POST", "/api/audio/output"):
            handleSetOutputDevice(body: body, connection: connection)
        case ("GET", "/api/audio/input"):
            handleGetInputDevice(connection: connection)
            
        default:
            sendResponse(connection: connection, status: 404, body: [
                "error": "Not found",
                "available_endpoints": [
                    "Volume Control": [
                        "GET /api/status",
                        "GET /api/volume",
                        "POST /api/volume",
                        "GET /api/mute",
                        "POST /api/mute"
                    ],
                    "Media Control": [
                        "POST /api/media/play_pause",
                        "POST /api/media/play",
                        "POST /api/media/pause",
                        "POST /api/media/stop",
                        "POST /api/media/next",
                        "POST /api/media/previous",
                        "GET /api/media/state",
                        "GET /api/media/info",
                        "POST /api/media/seek",
                        "POST /api/media/shuffle",
                        "POST /api/media/repeat"
                    ],
                    "Audio Devices": [
                        "GET /api/audio/devices",
                        "GET /api/audio/output",
                        "POST /api/audio/output",
                        "GET /api/audio/input"
                    ]
                ]
            ])
        }
    }
    
    private func handleGetStatus(connection: NWConnection) {
        guard let systemVolume = systemVolume else {
            sendResponse(connection: connection, status: 500, body: ["error": "Audio system not available"])
            return
        }
        
        let volumePercent = Int(systemVolume.volume * 100)
        let mediaInfo = MusicControl.getCurrentTrackInfo()
        let musicRunning = MusicControl.isMusicRunning()
        
        let response: [String: Any] = [
            "volume": volumePercent,
            "muted": systemVolume.isMuted,
            "volume_control_available": systemVolume.hasVolumeControl(),
            "mute_control_available": systemVolume.hasMuteControl(),
            "media_control_available": true,
            "audio_device_control_available": true,
            "music_app_running": musicRunning,
            "playback_state": mediaInfo["state"] as? String ?? "stopped",
            "capabilities": [
                "volume_control",
                "mute_control",
                "media_playback",
                "audio_device_switching"
            ]
        ]
        
        sendResponse(connection: connection, status: 200, body: response)
    }
    
    private func handleGetVolume(connection: NWConnection) {
        guard let systemVolume = systemVolume else {
            sendResponse(connection: connection, status: 500, body: ["error": "Audio system not available"])
            return
        }
        
        let volumePercent = Int(systemVolume.volume * 100)
        sendResponse(connection: connection, status: 200, body: ["volume": volumePercent])
    }
    
    private func handleSetVolume(body: [String: Any]?, connection: NWConnection) {
        guard let systemVolume = systemVolume else {
            sendResponse(connection: connection, status: 500, body: ["error": "Audio system not available"])
            return
        }
        
        guard let body = body,
              let volume = body["volume"] as? Int,
              volume >= 0 && volume <= 100 else {
            sendResponse(connection: connection, status: 400, body: [
                "error": "Invalid volume value",
                "required": "volume (0-100)"
            ])
            return
        }
        
        systemVolume.volume = Float(volume) / 100.0
        sendResponse(connection: connection, status: 200, body: [
            "success": true,
            "volume": volume
        ])
    }
    
    private func handleGetMute(connection: NWConnection) {
        guard let systemVolume = systemVolume else {
            sendResponse(connection: connection, status: 500, body: ["error": "Audio system not available"])
            return
        }
        
        sendResponse(connection: connection, status: 200, body: ["muted": systemVolume.isMuted])
    }
    
    private func handleSetMute(body: [String: Any]?, connection: NWConnection) {
        guard let systemVolume = systemVolume else {
            sendResponse(connection: connection, status: 500, body: ["error": "Audio system not available"])
            return
        }
        
        guard let body = body,
              let muted = body["muted"] as? Bool else {
            sendResponse(connection: connection, status: 400, body: [
                "error": "Invalid mute value",
                "required": "muted (boolean)"
            ])
            return
        }
        
        systemVolume.isMuted = muted
        sendResponse(connection: connection, status: 200, body: [
            "success": true,
            "muted": muted
        ])
    }
    
    // MARK: - Media Control Handlers
    
    private func handleMediaPlayPause(connection: NWConnection) {
        do {
            try MusicControl.playPause()
            let state = MusicControl.getPlaybackState()
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "state": state
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to toggle playback"])
        }
    }
    
    private func handleMediaPlay(connection: NWConnection) {
        do {
            try MusicControl.play()
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "state": "playing"
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to play"])
        }
    }
    
    private func handleMediaPause(connection: NWConnection) {
        do {
            try MusicControl.pause()
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "state": "paused"
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to pause"])
        }
    }
    
    private func handleMediaStop(connection: NWConnection) {
        do {
            try MusicControl.stop()
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "state": "stopped"
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to stop"])
        }
    }
    
    private func handleMediaNext(connection: NWConnection) {
        do {
            try MusicControl.nextTrack()
            sendResponse(connection: connection, status: 200, body: ["success": true])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to skip to next track"])
        }
    }
    
    private func handleMediaPrevious(connection: NWConnection) {
        do {
            try MusicControl.previousTrack()
            sendResponse(connection: connection, status: 200, body: ["success": true])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to skip to previous track"])
        }
    }
    
    private func handleGetMediaState(connection: NWConnection) {
        let state = MusicControl.getPlaybackState()
        let isRunning = MusicControl.isMusicRunning()
        sendResponse(connection: connection, status: 200, body: [
            "state": state,
            "is_running": isRunning
        ])
    }
    
    private func handleGetMediaInfo(connection: NWConnection) {
        let info = MusicControl.getCurrentTrackInfo()
        sendResponse(connection: connection, status: 200, body: info)
    }
    
    private func handleMediaSeek(body: [String: Any]?, connection: NWConnection) {
        guard let body = body,
              let position = body["position"] as? Int else {
            sendResponse(connection: connection, status: 400, body: [
                "error": "Invalid position",
                "required": "position (seconds)"
            ])
            return
        }
        
        do {
            try MusicControl.seek(to: position)
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "position": position
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to seek"])
        }
    }
    
    private func handleMediaShuffle(connection: NWConnection) {
        do {
            try MusicControl.toggleShuffle()
            let shuffleState = MusicControl.getShuffleState()
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "shuffle": shuffleState
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to toggle shuffle"])
        }
    }
    
    private func handleMediaRepeat(connection: NWConnection) {
        do {
            try MusicControl.toggleRepeat()
            let repeatMode = MusicControl.getRepeatMode()
            sendResponse(connection: connection, status: 200, body: [
                "success": true,
                "repeat": repeatMode
            ])
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to toggle repeat"])
        }
    }
    
    // MARK: - Audio Device Handlers
    
    private func handleGetAudioDevices(connection: NWConnection) {
        let devices = AudioDevices.getAllDevices()
        let deviceList = devices.map { device in
            return [
                "id": device.id,
                "name": device.name,
                "uid": device.uid,
                "is_input": device.isInput,
                "is_output": device.isOutput
            ] as [String: Any]
        }
        
        sendResponse(connection: connection, status: 200, body: [
            "devices": deviceList,
            "count": devices.count
        ])
    }
    
    private func handleGetOutputDevice(connection: NWConnection) {
        guard let device = AudioDevices.getCurrentOutputDevice() else {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to get output device"])
            return
        }
        
        sendResponse(connection: connection, status: 200, body: [
            "id": device.id,
            "name": device.name,
            "uid": device.uid
        ])
    }
    
    private func handleSetOutputDevice(body: [String: Any]?, connection: NWConnection) {
        guard let body = body else {
            sendResponse(connection: connection, status: 400, body: [
                "error": "Missing body",
                "required": "name or id"
            ])
            return
        }
        
        do {
            if let deviceID = body["id"] as? UInt32 {
                try AudioDevices.setOutputDevice(deviceID: deviceID)
            } else if let name = body["name"] as? String {
                try AudioDevices.setOutputDevice(name: name)
            } else {
                sendResponse(connection: connection, status: 400, body: [
                    "error": "Invalid parameters",
                    "required": "name (string) or id (number)"
                ])
                return
            }
            
            if let newDevice = AudioDevices.getCurrentOutputDevice() {
                sendResponse(connection: connection, status: 200, body: [
                    "success": true,
                    "device": [
                        "id": newDevice.id,
                        "name": newDevice.name
                    ]
                ])
            } else {
                sendResponse(connection: connection, status: 200, body: ["success": true])
            }
        } catch {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to set output device"])
        }
    }
    
    private func handleGetInputDevice(connection: NWConnection) {
        guard let device = AudioDevices.getCurrentInputDevice() else {
            sendResponse(connection: connection, status: 500, body: ["error": "Failed to get input device"])
            return
        }
        
        sendResponse(connection: connection, status: 200, body: [
            "id": device.id,
            "name": device.name,
            "uid": device.uid
        ])
    }
    
    private func sendResponse(connection: NWConnection, status: Int, body: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let statusText = HTTPStatus.text(for: status)
            
            var response = "HTTP/1.1 \(status) \(statusText)\r\n"
            response += "Content-Type: application/json\r\n"
            response += "Content-Length: \(jsonData.count)\r\n"
            response += "Access-Control-Allow-Origin: *\r\n"
            response += "Connection: close\r\n"
            response += "\r\n"
            
            if let headerData = response.data(using: .utf8) {
                var fullResponse = Data()
                fullResponse.append(headerData)
                fullResponse.append(jsonData)
                
                connection.send(content: fullResponse, completion: .contentProcessed { error in
                    if let error = error {
                        print("❌ Send error: \(error)")
                    }
                    connection.cancel()
                })
            }
        } catch {
            print("❌ JSON serialization error: \(error)")
            connection.cancel()
        }
    }
}

// Helper for HTTP status codes
struct HTTPStatus {
    static func text(for code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}
