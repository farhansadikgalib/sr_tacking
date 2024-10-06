import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../service/location_service.dart';

class HomeController extends GetxController {
  late IO.Socket socket;
  var status = 'disconnected'.obs;
  var currentPosition = Rxn<Position>();
  late StreamSubscription<Position> positionStreamSubscription;
  final changedLocation = false.obs;
  final socketId = ''.obs;

  final x = 0.obs;
  @override
  void onInit() {
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
    }
  }

  void listenToLocationChanges() {
    LocationService locationService = LocationService();
    positionStreamSubscription = locationService.getPositionStream().listen(
      (Position position) {
          currentPosition.value = position;
          changedLocation.value = true;
          callJoinApi('11', position.latitude, position.longitude, "360", socketId.value);


        debugPrint('Location: ${position.latitude}, ${position.longitude}');
      },
    );
  }

  Future<void> callJoinApi(String uuid, double lat, double lon, String degree,
      String socketId) async {
    final dio = Dio();
    final url = 'http://192.168.101.34:3001/api/sr_join';
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
        x.value++;
      } else {
        debugPrint('Failed to call API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling API: $e');
    }
  }

}
