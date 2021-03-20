//
//  Cornucopia – (C) Dr. Lauer Information Technology
//
import Foundation

/// Stream consumers have no means to gather information about the actual connected device they're talking to.
/// This interface allows conveying a bunch of interesting static and dynamic metadata "out-of-band".
public extension Stream {

    static private var _handle1 = 0xdeadb001
    static private var _handle2 = 0xdeadb002
    static private var _handle3 = 0xdeadb003
    static private var _handle4 = 0xdeadb004
    static private var _handle5 = 0xdeadb005
    static private var _handle6 = 0xdeadb006
    static private var _handle7 = 0xdeadb007

    /// The original connection URL (all schemes)
    var CC_url: URL? {
        get { objc_getAssociatedObject(self, &Self._handle1) as? URL }
        set { objc_setAssociatedObject(self, &Self._handle1, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The device name.
    /// BLE devices populate this from the advertising info.
    /// EA devices populate this from the manufacturer-supplied attributes.
    var CC_name: String? {
        get { objc_getAssociatedObject(self, &Self._handle2) as? String }
        set { objc_setAssociatedObject(self, &Self._handle2, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The manufacturer name.
    /// EA devices populate this from the manufacturer-supplied attributes.
    var CC_manufacturer: String? {
        get { objc_getAssociatedObject(self, &Self._handle3) as? String }
        set { objc_setAssociatedObject(self, &Self._handle3, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The model name.
    /// EA devices populate this from the manufacturer-supplied attributes.
    var CC_model: String? {
        get { objc_getAssociatedObject(self, &Self._handle4) as? String }
        set { objc_setAssociatedObject(self, &Self._handle4, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The serial number.
    /// EA devices populate this from the manufacturer-supplied attributes.
    var CC_serialNumber: String? {
        get { objc_getAssociatedObject(self, &Self._handle5) as? String }
        set { objc_setAssociatedObject(self, &Self._handle5, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The firmware version.
    /// EA devices populate this from the manufacturer-supplied attributes.
    var CC_version: String? {
        get { objc_getAssociatedObject(self, &Self._handle6) as? String }
        set { objc_setAssociatedObject(self, &Self._handle6, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// The signal quality.
    var CC_rssi: Double? {
        get { objc_getAssociatedObject(self, &Self._handle7) as? Double }
        set { objc_setAssociatedObject(self, &Self._handle7, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
