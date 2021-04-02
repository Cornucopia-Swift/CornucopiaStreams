### CornucopiaStreams

_:shell: The "horn of plenty" – a symbol of abundance._

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Swift](https://github.com/Cornucopia-Swift/CornucopiaStreams/workflows/Swift/badge.svg)](https://github.com/Cornucopia-Swift/CornucopiaStreams/actions?query=workflow%3ASwift)

### Introduction

This library provides a convenient and extensible way to get an I/O stream pair to an URL.

`Foundation` comes with `getStreamsToHost(withName:port:inputStream:outputStream:)`,
which is clumsy to use and limited to TCP. `CornucopiaStreams` adds support for communicating with TTYs, external accessories
(using the `ExternalAccessory` framework), and Bluetooth Low Energy (BLE) devices (using the `CoreBluetooth` framework).

_Unfortunately, Linux support is not complete yet. Apart from the missing `ExternalAccessory` and `CoreBluetooth` infrastructure
(which, at least in the BLE case, could be substituted), the `Stream` class is missing the convenience accessor `Stream.getStreamsToHost`_.

### Usage

Open a connection to a tty:

```swift
import CornucopiaStreams

let url = URL(string: "tty:///dev/cu.serial-123456")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Open a connection to a tcp host:

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

Open a connection to a BLE device:

```swift
import CornucopiaStreams

let url = URL(string: "ble://FFF0")!
Stream.CC_getStreamPair(to: url) { result in
    guard case .success(let (inputStream, outputStream)) = result else { fatalError() }
    … do something with the streams …
}
```

Some of the streams provide metadata, e.g., the `name` for BLE devices, which you can access via the Streams `CC_meta` property.

### Contributions

Feel free to use under the terms of the MIT, if you find anything helpful here. Contributions are always welcome! Stay safe and sound!
