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
            
        default:
            sendResponse(connection: connection, status: 404, body: [
                "error": "Not found",
                "available_endpoints": [
                    "GET /api/status",
                    "GET /api/volume",
                    "POST /api/volume",
                    "GET /api/mute",
                    "POST /api/mute"
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
        let response: [String: Any] = [
            "volume": volumePercent,
            "muted": systemVolume.isMuted,
            "volume_control_available": systemVolume.hasVolumeControl(),
            "mute_control_available": systemVolume.hasMuteControl()
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
