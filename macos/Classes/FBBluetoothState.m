#import "FBBluetoothState.h"

NSString *const FBBluetoothStateUnknown = @"STATE_UNKNOWN";
NSString *const FBBluetoothStateResetting = @"STATE_RESETTING";
NSString *const FBBluetoothStateUnsupported = @"STATE_UNSUPPORTED";
NSString *const FBBluetoothStateUnauthorized = @"STATE_UNAUTHORIZED";
NSString *const FBBluetoothStatePoweredOff = @" STATE_OFF";
NSString *const FBBluetoothStatePoweredOn = @"STATE_ON";

NSString *bluetoothStateDescription(NSString *const bluetoothState) {
    if (bluetoothState == FBBluetoothStateUnknown) {
        return @"Blutooth state unknown.";
    } else if (bluetoothState == FBBluetoothStateResetting) {
        return @"Bluetooth is resetting.";
    } else if (bluetoothState == FBBluetoothStateUnsupported) {
        return @"Your hardware does not support Bluetooth Low Energy";
    } else if (bluetoothState == FBBluetoothStateUnauthorized) {
        return @"Application not authorized to use Bluetooth Low Energy";
    } else if (bluetoothState == FBBluetoothStatePoweredOff) {
        return @"Bluetooth is powered off";
    } else if (bluetoothState == FBBluetoothStatePoweredOn) {
        return @"Bluetooth is on and available";
    } else {
        return @"Bluetooth state unknown";
    }
}
