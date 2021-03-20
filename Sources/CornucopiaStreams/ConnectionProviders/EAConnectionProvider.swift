//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import ExternalAccessory

public extension Stream {

    class EAConnection: Connection {

        var session: EASession?
        var proto: String!

        public override func setup() {
            guard let proto = self.url.host else {
                self.failWith(error: .invalidParameters)
                return
            }
            self.proto = proto
            do {
                let eaSession = try EASession.CC_establishToFirstSupportedDevice(supportingProtocol: proto)
                guard let istream = eaSession.inputStream, let ostream = eaSession.outputStream else {
                    self.failWith(error: .unableToConnect)
                    return
                }
                self.startSession(eaSession, inputStream: istream, outputStream: ostream)
            }
            catch {
                _ = Self.notificationHandle // trigger receiving notifications
                EAAccessoryManager.shared().registerForLocalNotifications()
            }
        }

        static let notificationHandle = NotificationCenter.default.addObserver(forName: Notification.Name.EAAccessoryDidConnect, object: nil, queue: nil) { n in
            guard let userInfo = n.userInfo else { return }
            guard let accessory = userInfo[EAAccessoryKey] as? EAAccessory else { return }
            Stream.CC_pendingConnections.forEach { element in
                guard let self = element.value as? EAConnection else { return }
                guard accessory.protocolStrings.contains(self.proto) else { return }
                guard let eaSession = EASession(accessory: accessory, forProtocol: self.proto) else {
                    self.failWith(error: .unableToConnect)
                    return
                }
                guard let istream = eaSession.inputStream, let ostream = eaSession.outputStream else {
                    self.failWith(error: .unableToConnect)
                    return
                }
                self.startSession(eaSession, inputStream: istream, outputStream: ostream)
            }
        }

        private func startSession(_ session: EASession, inputStream: InputStream, outputStream: OutputStream) {
            self.session = session
            inputStream.CC_name = session.accessory?.name
            inputStream.CC_manufacturer = session.accessory?.manufacturer
            inputStream.CC_model = session.accessory?.modelNumber
            inputStream.CC_serialNumber = session.accessory?.serialNumber
            self.succeedWith(istream: inputStream, ostream: outputStream)
        }
    }
}
