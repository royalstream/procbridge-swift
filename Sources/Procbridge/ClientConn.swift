//
//  PBClient.swift
//
//  First version created by Steven Burns on 9/4/20.
//

import Foundation
import Network

internal class ClientConn {
    private let nwconn : NWConnection
    private let semaphore : DispatchSemaphore
    private var result : (StatusCode, Any)?
    
    init(_ nwconn: NWConnection, _ data:Data) {
        self.nwconn = nwconn
        self.semaphore = DispatchSemaphore(value: 0)
        self.result = nil
        self.nwconn.stateUpdateHandler = { state in
            switch state {
            case .waiting(let error):
                self.fail(error)
            case .ready:
                nwconn.send(content: data, completion: .contentProcessed({ _ in self.receiveResponse() }))
            case .failed(let error):
                self.fail(error)
            default:
                break
            }
        }
    }
    
    func run() throws -> Any {
        self.nwconn.start(queue: .global())
        self.semaphore.wait()
        switch self.result {
        case (.goodResponse, let value)?:
            return value
        case (.badResponse, let msg)?:
            throw PBError.clientError(msg as! String)
        default:
            throw PBError.clientError("Unexpected error")
        }
    }
    
    private func complete(result : (StatusCode,Any)) {
        self.nwconn.cancel()
        self.result = result
        self.semaphore.signal()
    }
    
    private func fail<T>(_ error : T) {
        self.complete(result : (.badResponse, "\(error)"))
    }
    
    private func receiveResponse(_ prevdata : Data? = nil) {
        self.nwconn.receive(minimumIncompleteLength: 12, maximumLength: 4*1024) { (data, _, isComplete, error) in
            if let error = error {
                self.fail(error)
            }
            else if let data = data, !data.isEmpty {
                let data = prefix_data(data, with: prevdata)
                if let response = Protocol.readResponse(data) {
                    self.complete(result : response)
                } else if isComplete {
                    self.fail("Incomplete message received despite Complete flag")
                } else {
                    self.receiveResponse(data)
                }
            }
            else {
                self.fail("Warning: no errors but receive is empty")
            }
        }
    }
}

