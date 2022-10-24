//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation
#if canImport(ObjectiveC)
import Darwin
public let posix_read = Darwin.read
#else
import CoreFoundation
import Glibc
public let posix_read  = Glibc.read
#endif

/// An InputStream that deals with the FileHandle abstraction.
class FileHandleInputStream: InputStream {

    private let fileHandle: FileHandle
    private weak var runLoop: RunLoop?
    private var dummySource: CFRunLoopSource? = nil

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

        //FIXME: This API does not integrate with the runloop system, but is rather a libdispatch.
        _ = NotificationCenter.default.addObserver(forName: Notification.Name.NSFileHandleDataAvailable, object: self.fileHandle, queue: nil) { notification in
            //FIXME: Hence we need to do a little runloop dance here
            self.runLoop?.perform() {
                self._hasBytesAvailable = true
            }
            CFRunLoopWakeUp(self.runLoop?.getCFRunLoop())
        }
        // Must be called from a thread that has an active runloop, see https://developer.apple.com/documentation/foundation/nsfilehandle/1409270-waitfordatainbackgroundandnotify
        self.runLoop?.perform {
            self.fileHandle.waitForDataInBackgroundAndNotify()
        }
        self._streamStatus = .open
        CFRunLoopWakeUp(self.runLoop?.getCFRunLoop())
    }

    override var hasBytesAvailable: Bool { self._hasBytesAvailable }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard _streamStatus == .open else { return 0 }
        // For some reason, the NSFileHandle's read implementation seems to have severe bugs
        // both on Darwin- and non-Darwin-platforms, e.g.
        // "Encountered read failure 35 Resource temporarily unavailable",
        // if you try to read more than the actual bytes available in the read queue.
        // To play safe, we better use the lowlevel read(2) here.
        let nread = posix_read(self.fileHandle.fileDescriptor, buffer, len)
        guard nread >= 1 else {
            self.reportDelegateEvent(.endEncountered)
            return 0
        }
        self._hasBytesAvailable = false
        self.fileHandle.waitForDataInBackgroundAndNotify()
        return nread
    }

    override func close() {
        try? self.fileHandle.close()
        self._streamStatus = .closed
    }

    override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool { false }
    #if !os(Linux)
    override func property(forKey key: Stream.PropertyKey) -> Any? { nil }
    override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool { false }
    #endif
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.dummySource = CFRunLoopSource.CC_dummy()
        aRunLoop.CC_addSource(self.dummySource!)
        self.runLoop = aRunLoop
    }
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.runLoop = nil
        aRunLoop.CC_removeSource(self.dummySource!)
        self.dummySource = nil
    }
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
