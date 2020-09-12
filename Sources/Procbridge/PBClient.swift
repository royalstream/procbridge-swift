//
//  PBClient.swift
//
//  First version created by Steven Burns on 9/4/20.
//

import Foundation
import Network

public class PBClient {
    
    public let port : UInt16
    public let host : String
    
    public init(host : String, port : UInt16) {
        self.host = host
        self.port = port
    }
    
    public func request(method : String, payload : Any) throws -> Any {
        let data = Protocol.writeRequest(method: method, payload: payload)
        let nwconn = NWConnection(host: NWEndpoint.Host(self.host), port: NWEndpoint.Port(rawValue: self.port)!, using: .tcp)
        let session = ClientConn(nwconn, data)
        return try session.run()
    }
}

