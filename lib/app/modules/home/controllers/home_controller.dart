import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:background_service_easy/background_service_easy.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';

import '../../../service/location_service.dart';

class HomeController extends GetxController {
  late IO.Socket socket;
  var status = 'disconnected'.obs;
  var currentPosition = Rxn<Position>();
  var livePosition = Rxn<Position>();
  late StreamSubscription<Position> positionStreamSubscription;
  final changedLocation = false.obs;
  final socketId = ''.obs;

  final x = 0.obs;
  var logger = Logger();


  @override
  void onInit() {
    initBackgroundFetch();

    requestLocationPermission();
    super.onInit();
    connectToSocket();
    getLocation();
    listenToLocationChanges();
  }

  @override
  void onClose() {
    x.value = 0;
    positionStreamSubscription.cancel();
    socket.dispose();
    super.onClose();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        // Permission granted, you can use the location.
      }
    }

    if (await Permission.location.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void connectToSocket() {
    socket = IO.io('http://192.168.101.34:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('connected');
      status.value = 'connected';
      socketId.value = socket.id ?? 'No ID';
      debugPrint('Socket ID: ${socketId.value}');
    });

    socket.onDisconnect((_) {
      debugPrint('disconnected');
    });
  }

  void getLocation() async {
    LocationService locationService = LocationService();
    Position? position = await locationService.getCurrentLocation();
    if (position != null) {
      currentPosition.value = position;
      callJoinApi(
          '5', position.latitude, position.longitude, "360", socketId.value);
    }
  }

  void listenToLocationChanges() {
    LocationService locationService = LocationService();
    positionStreamSubscription = locationService.getPositionStream().listen(
      (Position position) {
        livePosition.value = position;
        debugPrint(
            'Live Location: ${position.latitude}, ${position.longitude}');
        if (currentPosition.value == null) {
          currentPosition.value = position;
          changedLocation.value = true;
        } else {
          if (Geolocator.distanceBetween(
                  currentPosition.value!.latitude,
                  currentPosition.value!.longitude,
                  position.latitude,
                  position.longitude) >
              0.004) {
            currentPosition.value = position;
            changedLocation.value = true;
            callJoinApi('5', position.latitude, position.longitude, "360",
                socketId.value);
          } else {
            debugPrint("Location not changed");
            changedLocation.value = false;
          }
        }

        debugPrint('Location: ${position.latitude}, ${position.longitude}');
      },
    );
  }

  Future<void> callJoinApi(String uuid, double lat, double lon, String degree,
      String socketId) async {
    x.value++;
    final dio = Dio();
    const url = 'http://192.168.101.34:3001/api/sr_join';
    final data = {
      'uuid': uuid,
      'lat': lat.toString(),
      'lon': lon.toString(),
      'degree': degree.toString(),
      'socket_id': socketId,
    };

    try {
      final response = await dio.post(url, data: data);
      if (response.statusCode == 200) {
        debugPrint('API call successful');
      } else {
        debugPrint('Failed to call API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling API: $e');
    }
  }

  void initBackgroundFetch() {
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 1,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        // This is the fetch event callback.
        logger.w("[BackgroundFetch] Event received: $taskId");
        closedapp();
        BackgroundFetch.finish(taskId);
      },
    ).then((int status) {
      logger.wtf('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      logger.d('[BackgroundFetch] configure ERROR: $e');
    });

    // Optionally, you can schedule a one-off task.
    BackgroundFetch.scheduleTask(TaskConfig(
      taskId: "com.aci.sr_management",
      delay: 100, // milliseconds
      periodic: false,
    ));
  }

  void closedapp() {
    // Your code to execute when the app is closed
    logger.e("App is closed. Executing closedapp function.");
  }
}
