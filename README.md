# procbridge-swift

ProcBridge is a super-lightweight IPC (Inter-Process Communication) protocol over TCP socket or Unix domain socket. It enables you to **send and recieve JSON** between processes easily. ProcBridge is much like a simplified version of HTTP protocol, but only transfer JSON values.

Please note that this repo is the **Swift implementation** of ProcBridge protocol. You can find detailed introduction of ProcBridge protocol in the main repository: [gongzhang/procbridge](https://github.com/gongzhang/procbridge).

# Installation

Add this repository as a Swift Package dependency.

# Requirements

- macOS 10.14 or later
- Xcode 11 or later

# Usage

Server side:

```swift
import Foundation
import Procbridge

let port:UInt16 = 8000

let server = PBServer(port : port) { (method,args) in
    switch method {
    case "echo":
        return args
    case "sum":
        let arr = args as! [Int]
        return arr.reduce(0,+)
    case "err":
        print("Server error \(args)")
        return 0
    default:
        return "Unknown action"
    }
}

server.start()

dispatchMain()
```

Client side:

```swift
import Foundation
import Procbridge

let port:UInt16 = 8000

let client = PBClient(host: "127.0.0.1", port: port)

print(try! client.request(method: "echo", payload: 123))
print(try! client.request(method: "echo", payload: ["a","b","c"]))
print(try! client.request(method: "sum", payload: [1,2,3,4]))
```


