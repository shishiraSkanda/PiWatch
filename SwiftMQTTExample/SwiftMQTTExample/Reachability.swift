//
//  Reachability.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 13/11/2016.
//  Copyright © 2016 Priyanka Gopakumar. All rights reserved.
//

/*
 
 Open Source code retrieved from http://stackoverflow.com/questions/30743408/check-for-internet-connection-in-swift-2-ios-9
 Author: Alvin George
 Retrieved on 13/11/2016
 Checks the device for internet connection (either wifi or mobile data)
 */

import Foundation
import SystemConfiguration

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, UnsafePointer($0))
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .Reachable
        let needsConnection = flags == .ConnectionRequired
        
        return isReachable && !needsConnection
    }
}
