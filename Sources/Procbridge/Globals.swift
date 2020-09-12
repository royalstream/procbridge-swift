import Foundation

internal enum PBError : Error {
    case serverError(String)
    case clientError(String)
}

internal enum StatusCode : UInt8 {
    case request = 0
    case goodResponse = 1
    case badResponse = 2
}

struct Version {
    private init() {}
    static let major : UInt8 = 1
    static let minor : UInt8 = 1
}

func prefix_data(_ data : Data, with optionalPrefix : Data?) -> Data {
    if var result = optionalPrefix {
        result.append(data) // copy-on-write, optionalPrefix remains unmodified
        return result
    } else {
        return data
    }
}
