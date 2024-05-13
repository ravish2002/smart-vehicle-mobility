import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:location/location.dart' as location;
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await flutterBeacon.initializeScanning;
    await flutterBeacon.initializeAndCheckScanning;
  } on PlatformException catch (e) {
    print('Not initialized flutter_beacon: ${e.toString()}');
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool broadcastSupported = false;
  bool broadcasting = false;
  double altitude = 0.0;
  double direction = 0.0;
  double speed = 0.0;
  location.Location _location = location.Location();
  // late StreamSubscription<location.LocationData> _locationStream;
  String _uuid = Uuid().v4();

  // final List<Region> regions = [];
  // List<Beacon> beacons = [];
  // // late StreamSubscription<RangingResult> _streamRanging;
  // // late StreamSubscription<MonitoringResult> _streamMonitoring;

  String encode(double angle) {
    // final uuidBytes = List.filled(16, 0);
    // final bytes = Uint8List.fromList(utf8.encode(angle.toStringAsFixed(2)));
    // uuidBytes.setRange(0, 8, bytes);
    // final uuidString = _byteToHex(uuidBytes);
    // return uuidString;

    String _numeric = angle.truncate().toString().padRight(4, 'A');
    String _precision =
        ((angle - angle.truncate()) * 10000).truncate().toString();

    // _uuid = _uuid.replaceRange(9, 13, _numeric);
    _uuid = _uuid.replaceRange(28, 36, _numeric + _precision);
    return _uuid;
  }

  // String _byteToHex(List<int> bytes) {
  //   return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  // }

  // void beginLiveLocation() {
  //   // _location.changeSettings(interval: 0);

  // }

  // void startBroadcast() {

  // }

  @override
  void initState() {
    // _location.enableBackgroundMode(enable: true);
    // _location.getLocation().then((event) {
    //   altitude = event.altitude!;
    //   direction = event.heading!;
    //   speed = event.speed!;
    // });

    flutterBeacon
        .startBroadcast(BeaconBroadcast(
            identifier: 'com.beaconDetector',
            proximityUUID: encode(altitude),
            major: (speed ~/ 2),
            minor: (direction ~/ 3)))
        .then((value) {
      flutterBeacon.isBroadcastSupported().then((value) {
        setState(() {
          broadcastSupported = value;
        });
      });
      flutterBeacon.isBroadcasting().then((value) {
        setState(() {
          broadcasting = value;
        });
      });
    });

    // if (Platform.isIOS) {
    //   // iOS platform, at least set identifier and proximityUUID for region scanning
    //   regions.add(Region(
    //       identifier: 'Apple Airlocate',
    //       proximityUUID: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'));
    // } else {
    //   // android platform, it can ranging out of beacon that filter all of Proximity UUID
    //   regions.add(Region(identifier: ''));
    // }

    // _streamRanging =
    //     flutterBeacon.ranging(regions).listen((RangingResult result) {
    //   setState(() {
    //     beacons += result.beacons;
    //   });
    // });

    // _streamMonitoring = flutterBeacon.monitoring(regions).listen((event) {
    //   setState(() {
    //     beacons.add(Beacon(
    //         proximityUUID: event.region.proximityUUID!,
    //         major: event.region.major!,
    //         minor: event.region.minor!,
    //         accuracy: 0.85));
    //   });
    // });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: Text('BLE Advertiser')),
            body: Center(
              child: Text(
                  'Broadcast Support: ${broadcastSupported}\nBroadcasting: ${broadcasting}'),
            )));
  }

  @override
  void dispose() {
    flutterBeacon.stopBroadcast();
    // _locationStream.cancel();
    super.dispose();
  }
}
