import Foundation
import Network

// a client connection from the perspective of the server
internal class ServerConn {
    
    private let nwconn : NWConnection
    private let server : PBServer

    init(_ nwconn: NWConnection, _ server : PBServer) {
        self.nwconn = nwconn
        self.server = server
        self.nwconn.stateUpdateHandler = { (state: NWConnection.State) in
            switch state {
            case .ready:
                self.receiveRequest()
            case .waiting(let error):
                self.fail(error)
            case .failed(let error):
                self.fail(error)
            default:
                break
            }
        }
        self.nwconn.start(queue: .global())
    }
    
    func fail<T>(_ error: T) {
        print("Server error: \(error)")
        stop()
    }
    
    func stop() {
        if self.nwconn.stateUpdateHandler != nil {
            self.nwconn.stateUpdateHandler = nil
            self.nwconn.cancel()
        }
    }

    private func sendResponse(_ method:String, _ params:Any) {
        var data : Data
        do {
            let result = try self.server.delegate(method, params)
            data = Protocol.writeGoodResponse(payload: result)
        } catch let error {
            data = Protocol.writeBadResponse(message: error.localizedDescription)
        }
        self.nwconn.send(content: data, completion: .contentProcessed({ _ in self.stop() }))
    }
    
    private func receiveRequest(_ prevdata : Data? = nil) {
        self.nwconn.receive(minimumIncompleteLength: 12, maximumLength: 4*1024) { (data, _, isComplete, error) in
            if let error = error {
                self.fail(error)
            }
            else if let data = data, !data.isEmpty {
                let data = prefix_data(data, with: prevdata)
                if let (method,params) = Protocol.readRequest(data) {
                    self.sendResponse(method, params)
                } else if isComplete {
                    self.fail("Warning: Incomplete message received despite Complete flag")
                } else {
                    self.receiveRequest(data)
                }
            }
            else {
                self.fail("Warning: no errors but receive is empty")
            }
        }
    }
}
