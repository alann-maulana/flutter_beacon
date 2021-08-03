import Cocoa
import FlutterMacOS
import ReactiveObjC
import CoreBluetooth

public class FlutterBeaconPlugin: NSObject, FlutterPlugin {
    static fileprivate let BeaconTimeToLiveInterval: TimeInterval = 15
    
    fileprivate var regionRanging = Array<FBRegion>();
    fileprivate var beacons = Array<FBBeacon>();
    fileprivate var beaconHistory: FBBeaconLog?;
    fileprivate var housekeepingSignal: RACSignal<NSDate>?;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_beacon", binaryMessenger: registrar.messenger)
        let instance = FlutterBeaconPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let streamRanging = FlutterEventChannel(name: "flutter_beacon_event", binaryMessenger: registrar.messenger)
        streamRanging.setStreamHandler(FBRangingHandler(plugin: instance))
        
        let streamChannelBluetooth = FlutterEventChannel(name: "flutter_bluetooth_state_changed", binaryMessenger: registrar.messenger)
        streamChannelBluetooth.setStreamHandler(FBBluetoothStateHandler())
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize",
             "initializeAndCheck":
            self.initialize(result: result)
        case "authorizationStatus":
            result("ALWAYS")
        case "bluetoothState":
            if let scanner = FBBeaconScanner.shared() {
                result(scanner.bluetoothState)
            } else {
                result(FBBluetoothStateUnknown)
            }
        case "setLocationAuthorizationTypeDefault",
             "checkLocationServicesIfEnabled",
             "requestAuthorization",
             "openBluetoothSettings",
             "openLocationSettings",
             "setScanPeriod",
             "setBetweenScanPeriod",
             "openApplicationSettings",
             "isBroadcastSupported":
            result(true)
        case "close":
            self.close()
        case "startBroadcast":
            self.startBroadcast(result: result)
        case "stopBroadcast":
            self.stopBroadcast(result: result)
        case "isBroadcasting":
            result(self.isBroadcasting())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(result: @escaping FlutterResult) {
        FBBeaconScanner.shared()
        result(true)
    }
    
    private func close() {
        
    }
    
    private func startBroadcast(result: @escaping FlutterResult) {
        
    }
    
    private func stopBroadcast(result: @escaping FlutterResult) {
        result(nil)
    }
    
    private func isBroadcasting() -> Bool {
        return false
    }
}

class FBBluetoothStateHandler: NSObject, FlutterStreamHandler {
    private var subscribe: RACDisposable?
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let scanner = FBBeaconScanner.shared() {
            subscribe = scanner.bluetoothStateSignal.deliver(on: RACScheduler.mainThread()).subscribeNext({ (bluetoothState) in
                if let state = bluetoothState as? String {
                    events(state)
                }
            })
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let subscribe = self.subscribe {
            subscribe.dispose()
        }
        return nil
    }
    
    
}

class FBRangingHandler: NSObject, FlutterStreamHandler {
    private let plugin: FlutterBeaconPlugin
    
    init(plugin: FlutterBeaconPlugin) {
        self.plugin = plugin
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if plugin.regionRanging.count != 0 {
            plugin.regionRanging.removeAll()
        }
        
        if let array = arguments as? Array<Dictionary<String, Any>> {
            array.forEach { (dict) in
                if let region = FBRegion(dictionary: dict) {
                    plugin.regionRanging.append(region)
                }
            }
        } else {
            return nil
        }
        
        if let scanner = FBBeaconScanner.shared() {
            let beaconSignal = scanner.beaconSignal.filter { (value) -> Bool in
                var inRegion = false
                if let beacon = value as? FBBeacon {
                    for region in self.plugin.regionRanging {
                        if region.isBeacon(inRegion: beacon) == true {
                            beacon.region = region
                            inRegion = true
                            break
                        }
                    }
                }
                
                return inRegion
            }
            
            plugin.beaconHistory = FBBeaconLog(beaconSignal: beaconSignal)
            
            beaconSignal.deliver(on: RACScheduler.mainThread()).subscribeNext { (beacon) in
                if let b = beacon as? FBBeacon {
                    let index = self.plugin.beacons.firstIndex { (find) -> Bool in
                        return find.isEqual(to: b)
                    }
                    if let index = index {
                        self.plugin.beacons[index] = b
                    } else {
                        self.plugin.beacons.append(b)
                    }
                    
                }
                
                var dictionaryRegionBeacons = [FBRegion: [FBBeacon]]()
                for beacon in self.plugin.beacons {
                    if let region = beacon.region {
                        if let _ = dictionaryRegionBeacons[region] {} else {
                            dictionaryRegionBeacons[region] = [];
                        }
                        dictionaryRegionBeacons[region]!.append(beacon)
                    }
                }
                
                dictionaryRegionBeacons.forEach { (args) in
                    let (region, beaconList) = args
                    var beacons = [[String:AnyObject]]()
                    for beacon in beaconList {
                        beacons.append(beacon.dictionaryBeacon())
                    }
                    
                    var result = [String:AnyObject]()
                    result["region"] = region.dictionaryFromRegion() as AnyObject
                    result["beacons"] = beacons as AnyObject
                    events(result)
                }
            }
            
            plugin.housekeepingSignal = RACSignal<NSDate>.interval(1, on: RACScheduler.mainThread())
            plugin.housekeepingSignal?.subscribeNext({ [self] (now) in
                if let now = now, scanner.scanning {
                    let beacons = plugin.beacons
                    for beacon in beacons {
                        let age = now.timeIntervalSince(beacon.lastUpdated)
                        if age > FlutterBeaconPlugin.BeaconTimeToLiveInterval {
                            var index = 0
                            for existing in plugin.beacons {
                                if existing.isEqual(to: beacon) {
                                    plugin.beacons.remove(at: index)
                                    break
                                }
                                index += 1
                            }
                        }
                    }
                }
            })
            
            scanner.startScanning()
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let scanner = FBBeaconScanner.shared() {
            plugin.beacons.removeAll()
            scanner.stopScanning()
        }
        return nil
    }
    
    
}
