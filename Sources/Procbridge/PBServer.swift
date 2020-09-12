//
//  PBServer.swift
//
//  First version created by Steven Burns on 9/4/20.
//

import Foundation
import Network

public class PBServer {
    let port : UInt16
    internal let delegate : ((String,Any) throws -> Any)
    private let listener : NWListener
    private var sessions : [ServerConn]
    
    public init(port : UInt16, delegate : @escaping ((String,Any) throws -> Any)) {
        self.port = port
        self.delegate = delegate
        self.listener = try! NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
        self.sessions = []
    }
    
    public var isStarted : Bool { return self.listener.stateUpdateHandler != nil }
    
    public func start() {
        precondition(!isStarted)
        self.listener.stateUpdateHandler = { state in
            switch state {
            case .failed(let error):
                self.stop()
                print("Server error: \(error)")
                exit(EXIT_FAILURE)
            default:
                break
            }
        }
        self.listener.newConnectionHandler = { nwconn in self.sessions.append(ServerConn(nwconn, self)) }
        self.listener.start(queue: .main)
        dispatchMain()
    }
    
    public func stop() {
        if isStarted {
            self.listener.stateUpdateHandler = nil
            self.listener.newConnectionHandler = nil
            self.listener.cancel()
            for sess in self.sessions {
                sess.stop()
            }
            self.sessions.removeAll()
        }
    }
}

