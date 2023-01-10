//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
#if canImport(IOBluetooth) && !targetEnvironment(macCatalyst)
import IOBluetooth

fileprivate let logger = Cornucopia.Core.Logger()

/// Managing the input/output stream pair for a `IOBluetoothDevice`.
public class RFCOMMBridge: NSObject {

    public let device: IOBluetoothDevice
    let channelID: BluetoothRFCOMMChannelID
    var channel: IOBluetoothRFCOMMChannel? = nil

    weak var inputStream: RFCOMMChannelInputStream!
    weak var outputStream: RFCOMMChannelOutputStream!

    /// Create the stream pair for the first applicable `CBCharacteristic` in the specified `CBService`.
    public init(forDevice device: IOBluetoothDevice, channelID: BluetoothRFCOMMChannelID) {
        self.device = device
        self.channelID = channelID
        super.init()
    }

    func openChannel() {
        let result = self.device.openRFCOMMChannelAsync(&channel, withChannelID: self.channelID, delegate: self)
        if result != kIOReturnSuccess {
            inputStream.rfcommChannelOpenComplete(result: result)
        }
    }

    func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        guard let channel = channel else { return -1 }
        let pointer: UnsafeMutableRawPointer = .init(mutating: buffer)
        let result = channel.writeSync(pointer, length: UInt16(len))
        guard result == kIOReturnSuccess else {
            logger.debug("Can't write to RFCOMM channel \(channel): \(result)")
            return -1
        }
        return min(Int(channel.getMTU()), len)
    }

    func closeChannel() {
        guard let channel = self.channel else { return }
        let result = channel.close()
        guard result == kIOReturnSuccess else {
            logger.debug("Can't close RFCOMM channel \(channel): \(result)")
            return
        }
    }

    deinit {
#if DEBUG
        print("\(self) destroyed")
#endif
    }
}

extension RFCOMMBridge: IOBluetoothRFCOMMChannelDelegate {

    public func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let data = Data(bytes: dataPointer, count: dataLength)
        self.inputStream.rfcommChannelIncomingData(data)
    }

    public func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        self.inputStream.rfcommChannelOpenComplete(result: error)
    }

    public func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        self.inputStream.rfcommChannelClosed()
        self.outputStream.rfcommChannelClosed()
    }

    public func rfcommChannelControlSignalsChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        logger.trace("rfcommChannelControlSignalsChanged")
    }

    public func rfcommChannelFlowControlChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        logger.trace("rfcommChannelFlowControlChanged")

    }

    public func rfcommChannelWriteComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn) {

    }

    public func rfcommChannelWriteComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn, bytesWritten length: Int) {

    }

    public func rfcommChannelQueueSpaceAvailable(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {

    }
}

#endif
