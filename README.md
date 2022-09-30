### CornucopiaTransport

_:shell: The "horn of plenty" – a symbol of abundance._

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift](https://github.com/Cornucopia-Swift/CornucopiaTransport/workflows/Swift/badge.svg)](https://github.com/Cornucopia-Swift/CornucopiaTransport/actions?query=workflow%3ASwift)

### Introduction

This library is a stream-based transport broker. It provides a convenient and extensible way to get an I/O stream pair to an URL – supporting various schemes, such as:

- `tcp`: A TCP stream.
- `tty`: A TTY/USB-Serial stream.
- `ble`: Bluetooth Low Energy ­– either as serial emulation over one or two characteristics or via an L2CAP connection oriented channel.
- `ea`: MFi External Accessory streams.

`Foundation` comes with `getStreamsToHost(withName:port:inputStream:outputStream:)`,
which is clumsy to use and limited to TCP on Apple ­– for other platforms, [swift-corelibs-foundation](https://github.com/apple/swift-corelibs-foundation)
is missing the whole infrastructure for network transfer.
`CornucopiaTransport` retrofits that support and adds the necessary glue code to support communicating with TTYs, external accessories
(using the `ExternalAccessory` framework), and Bluetooth Low Energy (BLE) devices (using the `CoreBluetooth` framework).

On non-Apple-platforms there is no support for BLE and EA, since both `ExternalAccessory` and `CoreBluetooth` are Apple's closed-source frameworks.
That said, it might be interesting to evaluate [BluetoothLinux](https://github.com/PureSwift/BluetoothLinux).

With the exception of BLE (where we have to do the actual bridging), the major purpose of this library is to aid setting up the stream connections. Once the connection phase is over, it does not keep track about the further state, hence you can close your streams whenever you like without having to notify `CornucopiaTransport`.

### Usage

The usage is the same for all kinds of URLs. Let's assume you want to open a TTY:

```swift
import CornucopiaTransport

let url = URL(string: "tty:///dev/cu.serial-123456")!
let streams = try await Cornucopia.Transport.connect(url)
… do something with the streams …
```

Following are URL examples for all the supported URL schemes:

#### TTY

`tty://adapter:19200/dev/cu.serial-123456`

- Scheme: `tty`
- Host: *ignored*
- Port: Bitrate (optional)
- Path: Filepath

#### TCP

`tcp://192.168.0.10:35000`

- Scheme: `tcp`
- Host: Hostname
- Port: Port
- Path: *ignored*

#### External Accessory

`ea://com.obdlink`

- Scheme: `ea`
- Host: External Accessory Protocol. Note that this needs to match the content of the `UISupportedExternalAccessoryProtocols` key in your `Info.plist`.
- Port: *ignored*
- Path: *ignored*

#### BLE (Serial-over-Characteristics / L2CAP)

```
ble://FFF0
ble://FFF0/E32E4466-A24A-E46B-EE79-436569D6FC6D
ble://FFF0:128/E32E4466-A24A-E46B-EE79-436569D6FC6D
```

- Scheme: `ble`
- Host: Service UUID
- Port: L2CAP PSM (optional)
- Path: Device UUID (optional)

#### Metadata

Some of the streams provide metadata, e.g., the `name` for BLE devices, which you can access via the `CC_meta` property.

### Roadmap

Before 1.0, this project needs a comprehensive testsuite.

After 1.0, we might tackle additional connection mechanisms, perhaps

- Bluetooth 3.x (rfcomm)?
- Implement BLE on Linux (e.g., using [PureSwift](https://github.com/PureSwift/Bluetooth)?
- SSL sockets?

### Contributions

Feel free to use under the terms of the MIT, if you find anything helpful here. Contributions are always welcome! Stay safe and sound!
