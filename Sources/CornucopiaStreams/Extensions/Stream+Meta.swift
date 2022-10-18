//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import CornucopiaCore
import Foundation

/// Stream consumers usually have little means to gather information about the actual connected device they're talking to.
/// This interface allows conveying a bunch of interesting static and dynamic metadata "out-of-band".
public extension Stream {

    @Cornucopia.Core.Protected
    private static var StreamMetaDict: [Int: Stream.Meta] = .init()

    internal func CC_storeMeta(_ meta: Meta) {
        let ptr = CC_memoryAddressOf(self)
        Self.StreamMetaDict[ptr] = meta
    }
    internal func CC_removeMeta() {
        let ptr = CC_memoryAddressOf(self)
        Self.StreamMetaDict.removeValue(forKey: ptr)
    }

    var CC_meta: Meta? {
        let ptr = CC_memoryAddressOf(self)
        return Self.StreamMetaDict[ptr]
    }

    final class Meta {

        /// The original connection URL (all schemes)
        public let url: URL

        /// The device name.
        /// BLE devices populate this from the advertising info.
        /// EA devices populate this from the manufacturer-supplied attributes.
        public internal(set) var name: String = ""

        /// The manufacturer name.
        /// EA devices populate this from the manufacturer-supplied attributes.
        public internal(set) var manufacturer: String = ""

        /// The model name.
        /// EA devices populate this from the manufacturer-supplied attributes.
        public internal(set) var model: String = ""

        /// The serial number.
        /// EA devices populate this from the manufacturer-supplied attributes.
        public internal(set) var serialNumber: String = ""

        /// The firmware version.
        /// EA devices populate this from the manufacturer-supplied attributes.
        public internal(set) var version: String = ""

        /// The signal quality.
        public internal(set) var rssi: Double = 0.0

        internal init(url: URL) { self.url = url }
    }
}
