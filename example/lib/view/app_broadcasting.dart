import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_beacon_example/controller/requirement_state_controller.dart';
import 'package:get/get.dart';

class TabBroadcasting extends StatefulWidget {
  @override
  _TabBroadcastingState createState() => _TabBroadcastingState();
}

class _TabBroadcastingState extends State<TabBroadcasting> {
  final controller = Get.find<RequirementStateController>();
  final clearFocus = FocusNode();
  bool broadcasting = false;

  final regexUUID = RegExp(
      r'[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}');
  final uuidController =
      TextEditingController(text: 'CB10023F-A318-3394-4199-A8730C7C1AEC');
  final majorController = TextEditingController(text: '0');
  final minorController = TextEditingController(text: '0');

  bool get broadcastReady =>
      controller.authorizationStatusOk == true &&
      controller.locationServiceEnabled == true &&
      controller.bluetoothEnabled == true;

  @override
  void initState() {
    super.initState();

    controller.startBroadcastStream.listen((flag) {
      if (flag == true) {
        initBroadcastBeacon();
      }
    });
  }

  initBroadcastBeacon() async {
    await flutterBeacon.initializeScanning;
  }

  @override
  void dispose() {
    clearFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(clearFocus),
        child: Obx(
          () => broadcastReady != true
              ? Center(child: Text('Please wait...'))
              : Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        uuidField,
                        majorField,
                        minorField,
                        SizedBox(height: 16),
                        buttonBroadcast,
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget get uuidField {
    return TextFormField(
      readOnly: broadcasting,
      controller: uuidController,
      decoration: InputDecoration(
        labelText: 'Proximity UUID',
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Proximity UUID required';
        }

        if (!regexUUID.hasMatch(val)) {
          return 'Invalid Proxmity UUID format';
        }

        return null;
      },
    );
  }

  Widget get majorField {
    return TextFormField(
      readOnly: broadcasting,
      controller: majorController,
      decoration: InputDecoration(
        labelText: 'Major',
      ),
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Major required';
        }

        try {
          int major = int.parse(val);

          if (major < 0 || major > 65535) {
            return 'Major must be number between 0 and 65535';
          }
        } on FormatException {
          return 'Major must be number';
        }

        return null;
      },
    );
  }

  Widget get minorField {
    return TextFormField(
      readOnly: broadcasting,
      controller: minorController,
      decoration: InputDecoration(
        labelText: 'Minor',
      ),
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Minor required';
        }

        try {
          int minor = int.parse(val);

          if (minor < 0 || minor > 65535) {
            return 'Minor must be number between 0 and 65535';
          }
        } on FormatException {
          return 'Minor must be number';
        }

        return null;
      },
    );
  }

  Widget get buttonBroadcast {
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.white, backgroundColor: broadcasting ? Colors.red : Theme.of(context).primaryColor,
      minimumSize: Size(88, 36),
      padding: EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );

    return ElevatedButton(
      style: raisedButtonStyle,
      onPressed: () async {
        if (broadcasting) {
          await flutterBeacon.stopBroadcast();
        } else {
          await flutterBeacon.startBroadcast(BeaconBroadcast(
            proximityUUID: uuidController.text,
            major: int.tryParse(majorController.text) ?? 0,
            minor: int.tryParse(minorController.text) ?? 0,
          ));
        }

        final isBroadcasting = await flutterBeacon.isBroadcasting();

        if (mounted) {
          setState(() {
            broadcasting = isBroadcasting;
          });
        }
      },
      child: Text('Broadcast${broadcasting ? 'ing' : ''}'),
    );
  }
}
