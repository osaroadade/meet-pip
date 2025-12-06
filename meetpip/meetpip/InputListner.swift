import Foundation
import Combine

struct Speaker: Decodable, Hashable {
    let avatarUrl: String
    let name: String
}

class InputListener: ObservableObject {
    static let shared = InputListener()
    
    @Published var speakers: [Speaker] = []
    
    // Run loop to read JSON from stdin
    func start() {
        DispatchQueue.global(qos: .userInteractive).async {
            let input = FileHandle.standardInput
            
            while true {
                // Native messaging sends 4 bytes of length, then the JSON message
                let lengthData = input.readData(ofLength: 4)
                if lengthData.count < 4 { break } // EOF
                
                let length: UInt32 = lengthData.withUnsafeBytes { rawBuffer in
                    // Assume native messaging uses little-endian 32-bit length prefix
                    let value = rawBuffer.load(as: UInt32.self)
                    return UInt32(littleEndian: value)
                }
                
                let jsonData = input.readData(ofLength: Int(length))
                if let message = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                   let type = message["type"] as? String {
                       
                    if type == "update", let speakersData = message["speakers"] as? [[String: Any]] {
                        let newSpeakers = speakersData.compactMap { dict -> Speaker? in
                            guard let url = dict["avatarUrl"] as? String,
                                  let name = dict["name"] as? String else { return nil }
                            return Speaker(avatarUrl: url, name: name)
                        }
                        
                        DispatchQueue.main.async {
                            self.speakers = newSpeakers
                        }
                    }
                }
            }
        }
    }
}

