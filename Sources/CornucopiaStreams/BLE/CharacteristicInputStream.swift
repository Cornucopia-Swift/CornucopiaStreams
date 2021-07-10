//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(CoreBluetooth)
import CoreBluetooth

public class CharacteristicInputStream: InputStream {

    fileprivate var incoming = Data()
    public let characteristic: CBCharacteristic

    public override var streamStatus: Stream.Status { self.status }
    public override var delegate: StreamDelegate? {
        set { self.delega = newValue }
        get { self.delega }
    }
    private var status: Stream.Status = .notOpen
    private var delega: StreamDelegate? = nil

    init(with characteristic: CBCharacteristic) {
        self.characteristic = characteristic
        super.init(data: Data())
    }

    public override func open() {
        self.status = .opening
        #if compiler(>=5.5) // catch up with iOS 15 & macOS 12 changed (#available would be better, but does not work here)
        self.characteristic.service?.peripheral?.setNotifyValue(true, for: self.characteristic)
        #else
        self.characteristic.service.peripheral.setNotifyValue(true, for: self.characteristic)
        #endif
        //NOTE: Open is asynchronous, the control flow will continue (eventually) in `bleSubscriptionCompleted`
    }

    public override func close() {
        self.status = .closed
        #if compiler(>=5.5) // catch up with iOS 15 & macOS 12 changed (#available would be better, but does not work here)
        self.characteristic.service?.peripheral?.setNotifyValue(false, for: self.characteristic)
        #else
        self.characteristic.service.peripheral.setNotifyValue(false, for: self.characteristic)
        #endif
        self.delegate?.stream?(self, handle: .endEncountered)
    }

    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard self.status == .open else { return -1 }

        let numberOfBytesToRead = min(self.incoming.count, len)
        let range = 0..<numberOfBytesToRead
        self.incoming.copyBytes(to: buffer, from: range)
        self.incoming = self.incoming.subdata(in: numberOfBytesToRead..<self.incoming.count)
        //self.incoming.removeFirst(numberOfBytesToRead) EXC_BREAKPOINT?
        return numberOfBytesToRead
    }

    public override var hasBytesAvailable: Bool { self.status == .open && !self.incoming.isEmpty }

    public override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { false }
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
}

internal extension CharacteristicInputStream {

    func bleSubscriptionCompleted(error: Error?) {
        guard error == nil else {
            self.status = .error
            self.delegate?.stream?(self, handle: .errorOccurred)
            return
        }
        self.status = .open
        self.delegate?.stream?(self, handle: .openCompleted)
        //FIXME: Should we try to read to find out whether there are already bytes lurking in the lowlevel buffer?
        //self.characteristic.service.peripheral.readValue(for: self.characteristic)
    }

    func bleReadCompleted(error: Error?) {
        guard error == nil else {
            self.delegate?.stream?(self, handle: .errorOccurred)
            return
        }
        guard let data = self.characteristic.value else { return }
        self.incoming.append(data)
        self.delegate?.stream?(self, handle: .hasBytesAvailable)
    }

    func bleDisconnected() {
        self.delegate?.stream?(self, handle: .hasBytesAvailable)
        self.delegate?.stream?(self, handle: .endEncountered)
    }
}
#endif
