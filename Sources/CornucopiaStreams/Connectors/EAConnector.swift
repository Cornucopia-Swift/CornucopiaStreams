//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(ExternalAccessory)
import ExternalAccessory
import OSLog
import Foundation

fileprivate let log = OSLog(subsystem: "EAConnection", category: "ConnectionHandling")

extension Cornucopia.Streams {

    /// A connector for MFi-program compliant devices external accessories.
    class EAConnector: BaseConnector {

        private static var didStartListeningForNotifications: Bool = false

        typealias ConnectionContinuation = CheckedContinuation<StreamPair, Swift.Error>
        var continuation: ConnectionContinuation? = nil
        var proto: String?

        /// Connect
        override func connect() async throws -> StreamPair {

            let url = self.meta.url
            guard let proto = url.host else { throw Error.invalidUrl }
            if let connectedAccessory = try EAAccessoryManager.shared().CC_connectedAccessoryForProtocol(proto) {
                guard let inputStream = EAInputStreamProxy(accessory: connectedAccessory, forProtocol: proto) else {
                    throw Error.unableToConnect("Can't create EAInputStream")
                }
                guard let outputStream = inputStream.session.outputStream else {
                    throw Error.unableToConnect("EASession output stream is nil")
                }
                self.installMetaData(for: connectedAccessory, inputStream: inputStream, outputStream: outputStream)
                return (inputStream, outputStream)
            }

            NotificationCenter.default.addObserver(self, selector: #selector(onEAAccessoryDidConnect), name: Notification.Name.EAAccessoryDidConnect, object: nil)
            if !Self.didStartListeningForNotifications {
                Self.didStartListeningForNotifications = true
                EAAccessoryManager.shared().registerForLocalNotifications()
            }
            return try await withCheckedThrowingContinuation { c in
                self.continuation = c
                self.proto = proto
            }
        }

        /// Cancel
        override func cancel() {
            guard let continuation = self.continuation else {
                os_log("Ignoring cancellation request without continuation", log: log)
                return
            }
            continuation.resume(throwing: Error.connectionCancelled)
        }

        @objc private func onEAAccessoryDidConnect(n: Notification) {
            guard let continuation = self.continuation else {
                os_log("Ignoring connection notification without continuation", log: log)
                return
            }
            guard let proto = self.proto else {
                os_log("Ignoring connection notification without proto", log: log)
                return
            }
            guard let connectedAccessory = try? EAAccessoryManager.shared().CC_connectedAccessoryForProtocol(proto) else { return }
            guard let inputStream = EAInputStreamProxy(accessory: connectedAccessory, forProtocol: proto) else {
                continuation.resume(throwing: Error.unableToConnect("Can't create EAInputStream"))
                self.continuation = nil
                self.proto = nil
                return
            }
            guard let outputStream = inputStream.session.outputStream else {
                continuation.resume(throwing: Error.unableToConnect("EASession output stream is nil"))
                self.continuation = nil
                self.proto = nil
                return
            }
            self.installMetaData(for: connectedAccessory, inputStream: inputStream, outputStream: outputStream)
            continuation.resume(returning: (inputStream, outputStream))
            self.continuation = nil
            self.proto = nil
        }

        #if DEBUG
        deinit {
            print("\(self) destroyed")
        }
        #endif
    }
}

private extension Cornucopia.Streams.EAConnector {

    func installMetaData(for accessory: EAAccessory, inputStream: InputStream, outputStream: OutputStream) {
        self.meta.name = accessory.name
        self.meta.manufacturer = accessory.manufacturer
        self.meta.model = accessory.modelNumber
        self.meta.serialNumber = "\(accessory.serialNumber) \(accessory.hardwareRevision)"
        self.meta.version = accessory.firmwareRevision
        inputStream.CC_storeMeta(self.meta)
        outputStream.CC_storeMeta(self.meta)
    }
}

#endif

