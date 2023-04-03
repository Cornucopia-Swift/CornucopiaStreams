//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
#if canImport(ExternalAccessory)
import ExternalAccessory

final class EAInputStreamProxy: ProxyInputStream {

    let session: EASession

    init?(accessory: EAAccessory, forProtocol protocolString: String) {
        guard let session = EASession(accessory: accessory, forProtocol: protocolString) else { return nil }
        self.session = session
        guard let inputStream = session.inputStream else { return nil }
        super.init(proxying: inputStream)
    }

    #if DEBUG
    deinit {
        print("\(self) destroyed")
    }
    #endif
}
#endif
