import Cocoa
import FlutterMacOS
import ReactiveObjC

public class FlutterBeaconPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_beacon", binaryMessenger: registrar.messenger)
        let instance = FlutterBeaconPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            self.initialize()
        case "initializeAndCheck":
            self.initializeAndCheck()
        case "setLocationAuthorizationTypeDefault":
            result(true)
        case "authorizationStatus":
            result("ALWAYS")
        case "checkLocationServicesIfEnabled":
            result(true)
        case "bluetoothState":
            result(FlutterMethodNotImplemented)
        case "requestAuthorization":
            result(true)
        case "openBluetoothSettings":
            result(true)
        case "openLocationSettings":
            result(true)
        case "setScanPeriod":
            result(true)
        case "setBetweenScanPeriod":
            result(true)
        case "openApplicationSettings":
            result(true)
        case "close":
            self.close()
        case "startBroadcast":
            self.startBroadcast(result: result)
        case "stopBroadcast":
            self.stopBroadcast(result: result)
        case "isBroadcasting":
            result(self.isBroadcasting())
        case "isBroadcastSupported":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize() {
        
    }
    
    private func initializeAndCheck() {
        
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
