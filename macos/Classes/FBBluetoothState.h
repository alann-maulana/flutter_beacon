#import <Foundation/Foundation.h>

/**
 *  State unknown, update imminent.
 */
extern NSString *const FBBluetoothStateUnknown;

/**
 *  The connection with the system service was momentarily lost, update imminent.
 */
extern NSString *const FBBluetoothStateResetting;

/**
 *  The platform doesn't support Bluetooth Low Energy.
 */
extern NSString *const FBBluetoothStateUnsupported;

/**
 *  The app is not authorized to use Bluetooth Low Energy.
 */
extern NSString *const FBBluetoothStateUnauthorized;

/**
 *  Bluetooth is powered off
 */
extern NSString *const FBBluetoothStatePoweredOff;

/**
 *  Bluetooth is currently powered on and available to use.
 */
extern NSString *const FBBluetoothStatePoweredOn;

NSString *bluetoothStateDescription(NSString *const bluetoothState);
