/*
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Pingspeed.click ©2023
 */

import Foundation

public struct PSReachability {
        
    public struct PingSpeedModel:Codable {
        let time:Int
        let ping:Int
        let backhash:Int
    }
    
    public enum ReachabilityState {
        case perfect(Int, PingSpeedModel)
        case fast(Int, PingSpeedModel)
        case normal(Int, PingSpeedModel)
        case slow(Int, PingSpeedModel)
        case shit(Int, PingSpeedModel)
        case error(Error?, PingSpeedModel?)
    }
    
    public let version = "1.0"
    public let maxTimeout:TimeInterval
    
    public init(maxTimeout:TimeInterval = 1000) {
        self.maxTimeout = maxTimeout + 1
        Task {
            NotificationCenter.default.post(name: Notification.Name.reachabilityChanged,
                                            object: ["State": await PSReachability.shared.updateReachability() ])
        }
    }
    
    public static let shared = {
        return PSReachability()
    }()
    
    public func updateReachability() async -> ReachabilityState {
        let url = URL(string: "https://api.pingspeed.click/\(Int(Date().timeIntervalSince1970 * 1000))/\(self.randomHash(of:12))")!
        var pingState:ReachabilityState = .error(nil, nil)
        
        do {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = self.maxTimeout
            sessionConfig.timeoutIntervalForResource = self.maxTimeout
            
            let session = URLSession(configuration: sessionConfig)
           
            let (data, _) = try await session.data(from: url)
            let reachabilityState = try JSONDecoder().decode(PingSpeedModel.self, from: data)
            
            if (reachabilityState.ping) < 10 {
                return .perfect(reachabilityState.ping, reachabilityState)
            } else  if (reachabilityState.ping) < 50 {
                pingState = .fast(reachabilityState.ping, reachabilityState)
            } else  if (reachabilityState.ping) < 200 {
                pingState = .normal(reachabilityState.ping, reachabilityState)
            } else  if (reachabilityState.ping) < 500 {
                pingState = .slow(reachabilityState.ping, reachabilityState)
            } else {
                pingState = .shit(reachabilityState.ping, reachabilityState)
            }
        } catch {
            pingState = .error(error, nil)
        }
        
        NotificationCenter.default.post(name: Notification.Name.reachabilityChanged,
                                        object: ["State": pingState ])
        
        return pingState
    }

    func randomHash(of n: Int) -> String {
        let digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        return String(Array(0..<n).map { _ in digits.randomElement()! })
    }
}

public extension Notification.Name {
    static let reachabilityChanged = Notification.Name("ReachabilityChanged")
}
