import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await flutterBeacon.initializeScanning;
    await flutterBeacon.initializeAndCheckScanning;
  } on PlatformException catch (e) {
    print('Not initialized flutter_beacon: ${e.toString()}');
  }

  AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Proximity Notification')
      ],
      debug: true);

  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Region> regions = [];
  List<Beacon> beacons = [];
  DateTime _timeOfDay = DateTime.now();
  late StreamSubscription<RangingResult> _streamRanging;
  // late StreamSubscription<MonitoringResult> _streamMonitoring;

  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then((value) {
      if (!value) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    if (Platform.isIOS) {
      // iOS platform, at least set identifier and proximityUUID for region scanning
      regions.add(Region(
          identifier: 'Apple Airlocate',
          proximityUUID: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'));
    } else {
      // android platform, it can ranging out of beacon that filter all of Proximity UUID
      regions.add(Region(identifier: 'com.beaconDetector'));
    }

    // flutterBeacon.setBetweenScanPeriod(1);
    flutterBeacon.setScanPeriod(20);

    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
      setState(() {
        if (result.beacons.isNotEmpty) {
          beacons = result.beacons;
          _timeOfDay = DateTime.now();

          bool diff = false;
          for (int i = 0; i < result.beacons.length; i++) {
            bool match = false;
            for (int j = 0; j < beacons.length; j++) {
              if (beacons[j].macAddress == result.beacons[i].macAddress) {
                match = true;
                break;
              }
            }
            if (!match) {
              diff = true;
            }
          }
          if (diff) {
            sendNotification();
          }
        } else if (DateTime.now().difference(_timeOfDay).inSeconds > 2) {
          beacons = [];
        }
      });
    });

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

  String decode(String uuid) {
    String _numeric = uuid.substring(28, 31);
    RegExp regex = RegExp(
        r'^\d+'); // Regular expression to match numeric characters at the beginning
    Match match = regex.firstMatch(_numeric)!;
    _numeric = match.group(0)!; // Find the first match
    String _precision = uuid.substring(32, 36);
    return (_numeric + "." + _precision);
  }

  // List<int> _hexToByte(String hex) {
  //   final list = <int>[];
  //   for (var i = 0; i < hex.length; i += 2) {
  //     list.add(int.parse(hex.substring(i, i + 2), radix: 16));
  //   }
  //   return list;
  // }

  AppBar appBar = AppBar(
    title: Text('BLE Scanner'),
  );

  void sendNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            title: 'Warning! Proximity Detected',
            body: 'New Beacon detected close-by, stay alert!'));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height =
        MediaQuery.of(context).size.height - appBar.preferredSize.height;
    return Scaffold(
        appBar: appBar,
        body: Container(
          width: width,
          height: height,
          child: Column(
            children: [
              ...beacons.map((e) {
                double dist = pow(10, (e.txPower! - e.rssi) / 30).toDouble();
                return Text(
                    'Proximity UUID: ${e.proximityUUID}\nDistance: $dist meters\nMac Address: ${e.macAddress}\nDirection: ${e.minor}\nSpeed: ${(e.major)} m/s\nAltitude: 7.856');
              }).toList()
            ],
          ),
        ));
  }

  @override
  void dispose() {
    _streamRanging.cancel();
    // _streamMonitoring.cancel();
    super.dispose();
  }
}
