# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CornucopiaStreams is a Swift library that provides a unified stream-based transport broker for multiple connection schemes (TCP, TTY, BLE, External Accessory, RFCOMM). The main entry point is `Cornucopia.Streams.connect(url:)` which returns a `StreamPair` (input/output streams) for any supported URL scheme.

## Build and Development Commands

### Building
```bash
swift build
```

### Testing
```bash
swift test
```

### Running the Example CLI Tool
```bash
swift run streamer <url>
# Example: swift run streamer "tcp://192.168.1.10:8080"
```

### Building for Specific Platforms
The package supports macOS (.v13+), iOS (.v16+), tvOS (.v16+), watchOS (.v9+), and Linux.

## Architecture

### Core Components

**Broker Pattern**: The central `Cornucopia.Streams.Broker` (actor) manages all connections and maintains a registry of pending connections to prevent duplicates.

**Connector Protocol**: All transport implementations conform to the `Connector` protocol:
- `init(url: URL)` - Initialize with target URL
- `connect() async throws -> StreamPair` - Establish connection
- `cancel()` - Cancel ongoing connection

**BaseConnector**: Abstract base class that provides common functionality and metadata handling via `Stream.Meta`.

### URL Schemes and Connectors

- **TCP**: `tcp://host:port` → `TCPConnector` (simple wrapper around Foundation's stream APIs)
- **TTY**: `tty://adapter:bitrate/dev/path` → `TTYConnector` (serial/USB devices)
- **BLE**: `ble://serviceUUID[:psm][/deviceUUID]` → `BLEConnector` (Bluetooth Low Energy)
- **EA**: `ea://protocol` → `EAConnector` (MFi External Accessory, iOS only)  
- **RFCOMM**: `rfcomm://mac:channel` → `RFCOMMConnector` (Bluetooth Classic, macOS only)

### Stream Proxies and Bridges

For complex protocols like BLE and RFCOMM, the library uses proxy streams and bridge objects:

- **BLE**: `BLEBridge` manages characteristic-based or L2CAP communication, with `BLECharacteristicInputStream/OutputStream` proxies
- **RFCOMM**: `RFCOMMBridge` with `RFCOMMChannelInputStream/OutputStream`
- **TTY/EA**: Use input stream proxies (`TTYInputStreamProxy`, `EAInputStreamProxy`)

### Platform Conditional Compilation

The codebase uses extensive `#if canImport()` blocks to support different Apple frameworks:
- `CoreBluetooth` for BLE support
- `ExternalAccessory` for MFi accessories  
- `IOBluetooth` for RFCOMM (not on macCatalyst)

### Dependencies

- **CornucopiaCore**: Provides logging and common utilities
- **CSocketHelper**: C helper for low-level socket operations
- **LineNoise** (streamer only): For CLI interaction

## Key Implementation Notes

### Stream Event Handling
The library returns proxy objects in some cases, so stream event delegates should use `is InputStream`/`is OutputStream` checks rather than direct object comparison.

### Connection Lifecycle
1. `Broker.connect(to:)` creates appropriate connector
2. Connector stored in `pending` registry during connection
3. Connector removed from registry when connection completes/fails
4. Task cancellation triggers `connector.cancel()`

### Input Stream Priority  
Always open input streams before output streams - core logic resides in input stream implementations for bridged connections.

### Metadata Access
Streams provide metadata via the `CC_meta` property (defined in `Stream+Meta.swift`).

## Testing

The test suite is minimal currently (`CornucopiaStreamsTests.swift` only contains a placeholder test). Real testing would require physical devices or simulators for BLE/RFCOMM/EA schemes.