import Foundation

internal class Protocol {
 
    static let METHOD = "method"
    static let PAYLOAD = "payload"
    static let MESSAGE = "message"
    static let HEADER:[UInt8] = [112, 98, Version.major, Version.minor] // [ 'p','b',1,1 ]
    
    static func read(_ data : Data) -> (StatusCode, Any)? {
        precondition(HEADER == [UInt8](data[0..<4]))
        let statuscode = StatusCode(rawValue: data[4])!
        // data[5], data[6] are reserved
        let bodyLen = data[7] | (data[8] << 8) | (data[9] << 16) | (data[10] << 24);
        var jsondata = data.advanced(by: 11)
        if jsondata.count < bodyLen { return nil }
        if jsondata.count > bodyLen {
            jsondata = jsondata[0..<bodyLen]
        }
        return (statuscode, try! JSONSerialization.jsonObject(with: jsondata, options:[]))
    }
    
    static func write(_ statuscode : StatusCode, _ jsonobject : Any) -> Data {
        var data = Data()
        data.append(contentsOf: HEADER)
        data.append(contentsOf: [statuscode.rawValue,0,0]) // statuscode, reserved, reserved
        let jsondata = try! JSONSerialization.data(withJSONObject: jsonobject, options: [])
        var lenarr:[UInt8] = []
        for i in 0..<4 {
            lenarr.append(UInt8((jsondata.count >> (i * 8)) & 0xFF))
        }
        data.append(contentsOf: lenarr)
        data.append(jsondata)
        return data
    }
    
    static func readRequest(_ data : Data) -> (String, Any)? {
        guard let (statuscode, json) = self.read(data) else { return nil }
        precondition(statuscode == .request)
        if let json = json as? [String : Any] {
            return (json[METHOD] as! String, json[PAYLOAD]!)
        } else {
            print("Unexpected JSON result: \(json)")
            return nil
        }
    }
    
    static func readResponse(_ data : Data) -> (StatusCode, Any)? {
        guard let (statuscode, json) = self.read(data) else { return nil }
        if let json = json as? [String : Any] {
            precondition(statuscode == .goodResponse || statuscode == .badResponse)
            if statuscode == .goodResponse {
                return (.goodResponse, json[PAYLOAD]!)
            } else {
                return (.badResponse, json[MESSAGE]!)
            }
        } else {
            print("Unexpected JSON result: \(json)")
            return nil
        }
    }
    
    static func writeRequest(method : String, payload : Any) -> Data {
        var dict : [String : Any] = [:]
        dict[METHOD] = method
        dict[PAYLOAD] = payload
        return write(.request, dict)
    }
    
    static func writeGoodResponse(payload : Any) -> Data {
        var dict : [String : Any] = [:]
        dict[PAYLOAD] = payload
        return write(.goodResponse, dict)
    }
    
    static func writeBadResponse(message : String) -> Data {
        var dict : [String : Any] = [:]
        dict[MESSAGE] = message
        return write(.badResponse, dict)
    }
}
