//
//  (C) Dr. Michael 'Mickey' Lauer <mickey@vanille-media.de>
//
import Foundation

class FileHandleInputStream: InputStream {

    private let fileHandle: FileHandle

    private var _streamStatus: Stream.Status
    private var _streamError: Error?
    private var _delegate: StreamDelegate?

    init(fileHandle: FileHandle, offset: UInt64 = 0) {
        self.fileHandle = fileHandle
        if offset > 0 {
            self.fileHandle.seek(toFileOffset: offset)
        }
        self._streamStatus = .notOpen
        self._streamError = nil
        super.init(data: Data())
    }

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

        _ = NotificationCenter.default.addObserver(forName: Notification.Name.NSFileHandleDataAvailable, object: self.fileHandle, queue: nil) { notification in
            #if os(Linux)
            self._delegate?.stream(self, handle: .hasBytesAvailable)
            #else
            self._delegate?.stream?(self, handle: .hasBytesAvailable)
            #endif
        }
        self.fileHandle.waitForDataInBackgroundAndNotify()
        self._streamStatus = .open
        #if os(Linux)
        self.delegate?.stream(self, handle: .openCompleted)
        #else
        self.delegate?.stream?(self, handle: .openCompleted)
        #endif
    }

    override var hasBytesAvailable: Bool { true }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard _streamStatus == .open else { return 0 }
        guard let data = try? self.fileHandle.read(upToCount: 1) else {
            #if os(Linux)
            self._delegate?.stream(self, handle: .endEncountered)
            #else
            self._delegate?.stream?(self, handle: .endEncountered)
            #endif
            return 0
        }
        if data.count > 0 {
            buffer[0] = data[0]
            self.fileHandle.waitForDataInBackgroundAndNotify()
        }
        return data.count
    }

    override func close() {
        self._streamStatus = .closed
    }

    override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { false }
    #if !os(Linux)
    override func property(forKey key: Stream.PropertyKey) -> Any? { nil }
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool { false }
    #endif
    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) { }
}
