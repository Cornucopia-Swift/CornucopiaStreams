//
//  (C) Dr. Michael 'Mickey' Lauer <mickey@vanille-media.de>
//
import Foundation

class FileHandleOutputStream: OutputStream {

    private let fileHandle: FileHandle

    private var _streamStatus: Stream.Status
    private var _streamError: Error?
    private var _delegate: StreamDelegate?

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
        self._streamStatus = .notOpen
        self._streamError = nil
        super.init(toMemory: ())
    }

    #if os(Linux)
    required public init(toMemory: ()) {
        fatalError("unsupported")
    }
    #endif

    override var streamStatus: Stream.Status { _streamStatus }
    override var streamError: Error? { _streamError }

    override var delegate: StreamDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
        }
    }

    override func open() {
        guard self._streamStatus != .open else { return }
        self._streamStatus = .open
        self.delegate?.stream(self, handle: .openCompleted)
    }

    override var hasSpaceAvailable: Bool { true }

    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {

        let data = Data(bytes: buffer, count: len)
        self.fileHandle.write(data)
        return len
    }

    override func close() {
        self._streamStatus = .closed
    }

    #if !os(Linux)
    override func property(forKey key: Stream.PropertyKey) -> Any? { nil }
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool { false }
    #endif
    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
}
