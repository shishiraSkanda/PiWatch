PiWatch

Objective: This project was developed to demonstrate the ability to develop a comprehensive system using advanced mobile technologies.  

Description: 
PiWatch is a security surveillance system. An iOS application is integrated with Raspberry Pi connected to motion detector, sound sensor and video stream camera. The application alerts the user incase of an intrusion and provides option to either capture an image or live stream the area. MQTT, a lightweight messaging protocol for small sensors and mobile devices, is used to optimize high-latency.

* Leveraged on https://github.com/aciidb0mb3r/SwiftMQTT
* Based on MQTT Version 3.1.1 (http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718043)

# How to use

## Create MQTTSession object:
```swift
mqttSession = MQTTSession(host: "localhost", port: 1883, clientID: "swift", cleanSession: true, keepAlive: 15, useSSL: false)
```

## Connect
```swift
mqttSession.connect { (succeeded, error) -> Void in
  if succeeded {
    print("Connected!")
  }
}
```

## Subscribe
```swift
mqttSession.subscribe("/hey/cool", qos: MQTTQoS.AtLeastOnce) { (succeeded, error) -> Void in
 if succeeded {
    print("Subscribed!")
  }
}
```

## Unsubscribe
```swift
 mqttSession.unSubscribe(["/ok/cool", "/no/ok"]) { (succeeded, error) -> Void in
  if succeeded {
    print("unSubscribed!")
  }
}
```
## Publish
```swift
let jsonDict = ["hey" : "sup"]
let data = try! NSJSONSerialization.dataWithJSONObject(jsonDict, options: NSJSONWritingOptions.PrettyPrinted)

mqttSession.publishData(data, onTopic: "/hey/wassap", withQoS: MQTTQoS.AtLeastOnce, shouldRetain: false) { (succeeded, error) -> Void in
  if succeeded {
    print("Published!")
  }
}
```

## Conform to `MQTTSessionDelegate` to receive messages 
```swift
mqttSession.delegate = self
```
```swift
func mqttSession(session: MQTTSession, didReceiveMessage message: NSData, onTopic topic: String) {
	let stringData = NSString(data: message, encoding: NSUTF8StringEncoding) as! String
	print("data received on topic \(topic) message \(stringData)")
}
```

# Installation

## CocoaPods

Install using [CocoaPods](http://cocoapods.org) by adding the following lines to your Podfile:

````ruby
use_frameworks!
pod 'SwiftMQTT'  
````

# License
MIT

Authors: Naveed Zanoon, Priyanka Gopakumar, Shishira Skanda, Zaeem Siddiq
