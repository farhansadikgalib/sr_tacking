import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.onInit();
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          title: const Text('HomeView'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
              Text(
                controller.status.value,
                style: TextStyle(fontSize: 20),
              ),
              Text(
                controller.currentPosition.value == null
                    ? 'Getting location...'
                    : 'Location: ${controller.currentPosition.value!.latitude}, ${controller.currentPosition.value!.longitude}',
                style: const TextStyle(fontSize: 20),
              ),
              Icon(
                controller.changedLocation.value
                    ? Icons.location_on
                    : Icons.location_off,
                size: 50,
              ),
              Text("Api called: ${controller.apiCalled.value}"),
              Text("Socket ID: ${controller.socketId.value}"),
              Text("Live Position: ${controller.livePosition.value}"),
              Text("Current Position: ${controller.currentPosition.value}"),
            ],
          ),
        ),
      );
    });
  }
}
