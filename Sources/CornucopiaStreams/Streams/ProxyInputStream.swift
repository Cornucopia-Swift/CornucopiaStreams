//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// An InputStream proxy (base class).
class ProxyInputStream: InputStream {

    private var stream: InputStream

    override var streamStatus: Stream.Status { self.stream.streamStatus }
    override var streamError: Error? { self.stream.streamError }

    override var delegate: StreamDelegate? {
        get {
            return self.stream.delegate
        }
        set {
            self.stream.delegate = newValue
        }
    }

    init(proxying stream: InputStream) {
        self.stream = stream
        super.init(data: .init())
    }

    override func open() { self.stream.open() }
    override var hasBytesAvailable: Bool { self.stream.hasBytesAvailable }
    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int { self.stream.read(buffer, maxLength: len) }
    override func close() { self.stream.close() }
    override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { false }
#if canImport(ObjectiveC)
    override func property(forKey key: Stream.PropertyKey) -> Any? { nil }
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool { false }
#endif
    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { self.stream.schedule(in: aRunLoop, forMode: mode) }
    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { self.stream.remove(from: aRunLoop, forMode: mode) }
}

extension ProxyInputStream {

    func reportDelegateEvent(_ event: Stream.Event) {
#if os(Linux)
        self.delegate?.stream(self, handle: event)
#else
        self.delegate?.stream?(self, handle: event)
#endif
    }
}
