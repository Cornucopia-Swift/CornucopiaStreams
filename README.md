### CornucopiaStreams

_:shell: The "horn of plenty" – a symbol of abundance._

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift](https://github.com/Cornucopia-Swift/CornucopiaStreams/workflows/Swift/badge.svg)](https://github.com/Cornucopia-Swift/CornucopiaStreams/actions?query=workflow%3ASwift)

### Introduction

This library is a stream-based transport broker. It provides a convenient and extensible way to get an I/O stream pair to an URL – supporting various schemes, such as:

- `tcp`: A TCP stream.
- `tty`: A TTY/USB-Serial stream.
- `ble`: Bluetooth Low Energy ­– virtual UART via one or two characteristics or using an L2CAP connection oriented channel.
- `ea`: MFi External Accessory streams.
- `rfcomm`: Bluetooth Classic RFCOMM virtual UART.

While `Foundation` comes with `getStreamsToHost(withName:port:inputStream:outputStream:)`,
(which is clumsy to use and limited to TCP) on Apple's operating systems ­– for other platforms, [swift-corelibs-foundation](https://github.com/apple/swift-corelibs-foundation)
is missing the whole infrastructure for network transfer.
`CornucopiaStreams` retrofits that and adds the necessary glue code to also support communicating with TTYs, external accessories
(using the `ExternalAccessory` framework), Bluetooth Low Energy (BLE) devices (using the `CoreBluetooth` framework), and Bluetooth Classic devices (using the `IOBluetooth` framework).

On non-Apple-platforms there is no support for BLE, EA, and RFCOMM, since all of those are using Apple's closed-source frameworks.
Perspectively, it might be interesting to evaluate [BluetoothLinux](https://github.com/PureSwift/BluetoothLinux).

With the exception of BLE (where we have to do the actual bridging), the major purpose of this library is to aid setting up the stream connections.
Once the connecting phase is over, it does not keep track about the further state, hence you can close your streams whenever you like without having to notify `CornucopiaStreams`.

### Usage

The usage is the same for all kinds of URLs. Let's assume you want to open a TTY:

```swift
import CornucopiaStreams

let url = URL(string: "tty:///dev/cu.serial-123456")!
let streams = try await Cornucopia.Streams.connect(url)
… set the delegate on the streams …
… attach to your preferred runloop …
… handle stream events in your StreamDelegate …
```

**Application Note 1**: For some connection schemes, this library returns _proxy objects_ instead of the actual streams,
therefore you might receive stream events from objects other than the ones you have been returned.
If ­– in your `StreamDelegate` ­– you have previously compared the stream event objects to the stored objects,
you will have to adjust for that, e.g.:

```swift
public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    assert(self == Thread.current)

    logger.trace("Received stream \(aStream), event \(eventCode) in thread \(self.CC_number)")

    switch (aStream, eventCode) {

        //This will no longer work, since we may have received proxy objects:
        //case (self.input, .openCompleted):
        case (is InputStream, .openCompleted):
            self.delegate?.streamProtocolHandlerInputStreamReady(self.input)
            self.outputActiveCommand()

        case (is OutputStream, .openCompleted):
            self.delegate?.streamProtocolHandlerOutputStreamReady(self.output)
            self.outputActiveCommand()

        case (is OutputStream, .hasSpaceAvailable):
            self.outputActiveCommand()

        case (is InputStream, .hasBytesAvailable):
            self.inputActiveCommand()

        case (_, .endEncountered), (_, .errorOccurred):
            self.handleErrorCondition(stream: aStream, event: eventCode)
            self.delegate?.streamProtocolHandlerUnexpectedEvent(eventCode, on: aStream)

        default:
            logger.trace("Unhandled \(aStream): \(eventCode)")
            break
    }
}
```

**Application Note 2**: Due to the way the certain connection schemes are implemented (with bridges), most of the core logic
resides in the input streams. It is therefore important to always open the input stream before opening the output stream.

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

#### Bluetooth Classic (RFCOMM)

`rfcomm://00:0a:3a:22:68:73`

- Scheme: `rfcomm`
- Host: Bluetooth device MAC address.
- Port: RFCOMM Channel ID (optional)
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

- Implement RFCOMM & BLE on Linux (e.g., using [PureSwift](https://github.com/PureSwift/Bluetooth)?
- SSL sockets?

### Contributions

Feel free to use under the terms of the MIT, if you find anything helpful here. Contributions are always welcome! Stay safe and sound!
