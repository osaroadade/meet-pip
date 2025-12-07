import Foundation
import Combine

struct Speaker: Decodable, Hashable {
    let avatarUrl: String
    let name: String
}

class InputListener: ObservableObject {
    static let shared = InputListener()
    
    @Published var speakers: [Speaker] = []
    @Published var isMuted: Bool = false
    
    // Run loop to read JSON from stdin
    func start() {
        log("InputListener started")
        DispatchQueue.global(qos: .userInteractive).async {
            let input = FileHandle.standardInput
            
            while true {
               // log("Waiting for input...")
                // Native messaging sends 4 bytes of length, then the JSON message
                let lengthData = input.readData(ofLength: 4)
                if lengthData.count < 4 {
                    if lengthData.count > 0 {
                        self.log("Received data < 4 bytes: \(lengthData.count). EOF possibly?")
                    }
                    // Wait a bit before breaking to avoid spamming if standardInput is weird,
                    // but usually < 4 means stream closed.
                    Thread.sleep(forTimeInterval: 1.0)
                    break 
                }
                
                let length: UInt32 = lengthData.withUnsafeBytes { rawBuffer in
                    // Assume native messaging uses little-endian 32-bit length prefix
                    let value = rawBuffer.load(as: UInt32.self)
                    return UInt32(littleEndian: value)
                }
                
                // log("Header received. Expecting \(length) bytes of JSON.")
                
                let jsonData = input.readData(ofLength: Int(length))
                
                if jsonData.count != Int(length) {
                    self.log("Error: Expected \(length) bytes but got \(jsonData.count)")
                }
                
                if let message = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                   let type = message["type"] as? String {
                    
                    // log("Received valid message: \(type)")
                       
                    if type == "update", let speakersData = message["speakers"] as? [[String: Any]] {
                        let newSpeakers = speakersData.compactMap { dict -> Speaker? in
                            guard let url = dict["avatarUrl"] as? String,
                                  let name = dict["name"] as? String else { return nil }
                            return Speaker(avatarUrl: url, name: name)
                        }
                        
                        self.log("Updating speakers count: \(newSpeakers.count)")
                        
                        DispatchQueue.main.async {
                            self.speakers = newSpeakers
                        }
                    } else if type == "mute-state", let isMuted = message["isMuted"] as? Bool {
                        self.log("Updating mute state: \(isMuted)")
                        DispatchQueue.main.async {
                            self.isMuted = isMuted
                        }
                    }
                } else {
                    self.log("Failed to parse JSON")
                    if let str = String(data: jsonData, encoding: .utf8) {
                        self.log("Raw content: \(str)")
                    }
                }
            }
        }
    }
    
    // Send message to Chrome Extension
    func sendMuteToggle() {
        log("Sending mute toggle")
        let message: [String: Any] = ["type": "toggle-mute"]
        sendMessage(message)
    }
    
    private func sendMessage(_ message: [String: Any]) {
        DispatchQueue.global(qos: .userInteractive).async {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []) else { return }
            
            var length = UInt32(jsonData.count)
            let lengthData = Data(bytes: &length, count: 4)
            
            // Write length (4 bytes) then JSON data
            FileHandle.standardOutput.write(lengthData)
            FileHandle.standardOutput.write(jsonData)
        }
    }
    
    // Debug Logging - Chrome captures stderr from native messaging hosts
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[MeetPIP \(timestamp)] \(message)\n"
        
        // Write to stderr which Chrome logs
        if let data = logEntry.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

