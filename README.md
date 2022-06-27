### CornucopiaStreams

_:shell: The "horn of plenty" – a symbol of abundance._

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift](https://github.com/Cornucopia-Swift/CornucopiaStreams/workflows/Swift/badge.svg)](https://github.com/Cornucopia-Swift/CornucopiaStreams/actions?query=workflow%3ASwift)

### Introduction

This library provides a convenient and extensible way to get an I/O stream pair to an URL – supporting various schemes, such as:

- TCP (TCP stream)
- TTY (TTY stream)
- BLE w/ a serial emulation using one or two characteristics
- BLE w/ a L2CAP connection oriented channel, and
- EA (External Accessory streams).

`Foundation` comes with `getStreamsToHost(withName:port:inputStream:outputStream:)`,
which is clumsy to use and limited to TCP. `CornucopiaStreams` adds support for communicating with TTYs, external accessories
(using the `ExternalAccessory` framework), and Bluetooth Low Energy (BLE) devices (using the `CoreBluetooth` framework).

On non-Apple-platforms, only TCP and TTY are supported, as both `ExternalAccessory` and `CoreBluetooth` are private Apple frameworks – it might be interesting to evaluate [BluetoothLinux](https://github.com/PureSwift/BluetoothLinux).

### Usage

Open a connection to a TTY:

```swift
import CornucopiaStreams

let url = URL(string: "tty:///dev/cu.serial-123456")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

If you need the tty to be configured to a specific bitrate, supply this as the "port number", e.g. like that:

```swift
import CornucopiaStreams

let url = URL(string: "tty://adapter:19200/dev/cu.serial-123456")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Open a connection to a TCP host:

```swift
import CornucopiaStreams

let url = URL(string: "tcp://192.168.0.10:35000")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Open a connection to an external accessory:

```swift
import CornucopiaStreams

let url = URL(string: "ea://com.obdlink")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Open a connection to a BLE device providing service `FFF0`:

```swift
import CornucopiaStreams

let url = URL(string: "ble://FFF0")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Open a connection to the BLE device `E32E4466-A24A-E46B-EE79-436569D6FC6D` that provides service `FFF0`:

```swift
import CornucopiaStreams

let url = URL(string: "ble://FFF0/E32E4466-A24A-E46B-EE79-436569D6FC6D")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Since version 0.9.3, you can alternatively use an `async` call to connect to a stream:

Open a connection to the BLE device `E32E4466-A24A-E46B-EE79-436569D6FC6D` that provides service `FFF0`:

```swift
import CornucopiaStreams

let url = URL(string: "ble://FFF0/E32E4466-A24A-E46B-EE79-436569D6FC6D")!
let streams = try await Stream.CC_getStreamPair(to: url)
… do something with the streams …
```

Since version 0.9.7, you can open an L2CAP stream connection. Do this by supplying the PSM (Protocol Service Multiplexor)
as the "port number".

Open a connection to the BLE device `E32E4466-A24A-E46B-EE79-436569D6FC6D` that provides service `FFF0` and open an L2CAP
stream for the PSM `0x80` (128):

```swift
import CornucopiaStreams

let url = URL(string: "ble://FFF0:128/E32E4466-A24A-E46B-EE79-436569D6FC6D")!
let streams = try await Stream.CC_getStreamPair(to: url)
… do something with the streams …
```

#### Metadata

Some of the streams provide metadata, e.g., the `name` for BLE devices, which you can access via the `CC_meta` property.

### Roadmap to 1.0 and beyond

Before the big 1.0, this project wants to

- [ ] Provide a comprehensive testsuite.
- [ ] Support cancelling a pending connection.
- [ ] Support force-closing an active connection.
- [ ] Support `Task` cancellation for pending connections.

After 1.0, we might tackle additional connection mechanisms, perhaps

- Bluetooth 3.x (rfcomm)?
- Implement BLE on Linux (e.g., using [PureSwift](https://github.com/PureSwift/Bluetooth)?
- SSL sockets?

### Contributions

Feel free to use under the terms of the MIT, if you find anything helpful here. Contributions are always welcome! Stay safe and sound!
