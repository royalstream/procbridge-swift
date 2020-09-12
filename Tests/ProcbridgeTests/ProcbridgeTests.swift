import XCTest
@testable import Procbridge

final class ProcbridgeTests: XCTestCase {
    
    static let port: UInt16 = 8000
    static var server: PBServer!
    
    var client: PBClient!
    
    enum ServerError: String, Error {
        case invalidArguments
        case unknownMethod
    }
    
    static override func setUp() {
        server = PBServer(port: port) { method, args in
            switch method {
            case "echo":
                return args
                
            case "sum":
                if let arr = args as? [Int] {
                    return arr.reduce(0, +)
                } else {
                    throw ServerError.invalidArguments
                }
                
            default:
                throw ServerError.unknownMethod
            }
        }
        server.start(in: DispatchQueue.global())
    }
    
    static override func tearDown() {
        server.stop()
    }
    
    override func setUp() {
        client = PBClient(host: "localhost", port: ProcbridgeTests.port)
    }
    
    override func tearDown() {
        client = nil
    }
    
    // MARK: - Test Cases
    
    func testEcho() throws {
        XCTAssertEqual(echo(NSNull()), NSNull())
        
        XCTAssertEqual(echo(true), true)
        XCTAssertEqual(echo(false), false)
        
        for i in 1...10 {
            XCTAssertEqual(echo(i), i)
            XCTAssertEqual(echo(1 / Double(i)), 1 / Double(i))
            
            let text = String(repeating: "some text\n", count: i)
            XCTAssertEqual(echo(text), text)
        }
        
        var array: [Int] = []
        for i in 0..<10 {
            XCTAssertEqual(echo(array), array)
            array.append(i)
        }
        
        var dict: [String: Int] = [:]
        for i in 0..<10 {
            XCTAssertEqual(echo(dict), dict)
            dict["\(i)"] = i
        }
        
        XCTAssertNotEqual(echo(1), 2)
    }
    
    func testSum() {
        XCTAssertEqual(sum([]), 0)
        XCTAssertEqual(sum([1]), 1)
        XCTAssertEqual(sum([1, 2, 3]), 6)
    }
    
    func testError() {
        XCTAssertEqual(sum(["bad"]), nil)
        
        do {
            _ = try client.request(method: "foo", payload: "bar")
            XCTFail()
        } catch PBError.clientError(let msg) {
            XCTAssertEqual(msg, ServerError.unknownMethod.localizedDescription)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    // MARK: - Helpers
    
    private func echo<T>(_ arg: T) -> T? {
        do {
            return try client.request(method: "echo", payload: arg) as? T
        } catch {
            XCTFail(error.localizedDescription)
            return nil
        }
    }
    
    private func sum(_ values: [Any]) -> Int? {
        do {
            if let reply = try client.request(method: "sum", payload: values) as? Int {
                return reply
            } else {
                XCTFail()
                return nil
            }
        } catch PBError.clientError(let msg) {
            XCTAssertEqual(msg, ServerError.invalidArguments.localizedDescription)
            return nil
        } catch {
            XCTFail(error.localizedDescription)
            return nil
        }
    }
    
}
