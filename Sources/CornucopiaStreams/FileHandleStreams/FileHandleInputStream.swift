//
//  (C) Dr. Michael 'Mickey' Lauer <mickey@vanille-media.de>
//
import Foundation

class FileHandleInputStream: InputStream {

    private let fileHandle: FileHandle

    private var _streamStatus: Stream.Status  = .notOpen {
        didSet {
            if self._streamStatus == .open {
                self.reportDelegateEvent(.openCompleted)
            }
        }
    }
    private var _streamError: Error? = nil
    private var _delegate: StreamDelegate?
    private var _hasBytesAvailable: Bool = false {
        didSet {
            if _hasBytesAvailable {
                self.reportDelegateEvent(.hasBytesAvailable)
            }
        }
    }

    init(fileHandle: FileHandle, offset: UInt64 = 0) {
        self.fileHandle = fileHandle
        if offset > 0 {
            self.fileHandle.seek(toFileOffset: offset)
        }
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
            self._hasBytesAvailable = true
        }
        // Must be called from a thread that has an active runloop, see https://developer.apple.com/documentation/foundation/nsfilehandle/1409270-waitfordatainbackgroundandnotify
        DispatchQueue.main.async { self.fileHandle.waitForDataInBackgroundAndNotify() }
        self._streamStatus = .open
    }

    override var hasBytesAvailable: Bool { self._hasBytesAvailable }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard _streamStatus == .open else { return 0 }
        #if canImport(FoundationNetworking)
        let maxLength = 1
        #else
        // For some reason, Darwin-platforms throw a "Encountered read failure 35 Resource temporarily unavailable", if you try to read more than the actual bytes available in the read queue.
        let maxLength = 1
        #endif
        guard let data = try? self.fileHandle.read(upToCount: maxLength) else {
            self.reportDelegateEvent(.endEncountered)
            return 0
        }
        if data.count > 0 {
            data.copyBytes(to: buffer, count: min(len, data.count))
            self._hasBytesAvailable = false
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

private extension FileHandleInputStream {

    func reportDelegateEvent(_ event: Stream.Event) {
        #if os(Linux)
        self._delegate?.stream(self, handle: event)
        #else
        self._delegate?.stream?(self, handle: event)
        #endif
    }
}
