import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// GPS -> current location - lat lng
/// GPS service permission - YES
/// GPS service on/off - YES
/// get data from GPS

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController googleMapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  final List<LatLng> _routPoints = [];
  Position? userLocation;

  //final LatLng _currentPosition = const LatLng(26.10373752721701, 88.83404596724567);

  @override
  void initState() {
    super.initState();
    listenCurrentLocation();
  }

  Future<void> listenCurrentLocation() async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) {
      final isServiceEnabled = await checkGPSServiceEnable();
      if (isServiceEnabled) {
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 10),
          ),
        ).listen((Position position) {
          print(position);
          userLocation = position;
          final LatLng newPosition =
              LatLng(position.latitude, position.longitude);
          _routPoints.add(newPosition);
          _updateMarkersAndPolyline(newPosition);
          googleMapController
              .animateCamera(CameraUpdate.newLatLng(newPosition));
        });
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      final result = await requestLocationPermission();
      if (result) {
        listenCurrentLocation();
      } else {
        Geolocator.openAppSettings();
      }
    }
  }

  Future<bool> isLocationPermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> checkGPSServiceEnable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  void _updateMarkersAndPolyline(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: position,
          //icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'My current location',
            snippet: '${position.latitude}, ${position.longitude}',
          ),
        ),
      );
      _polyLines.clear();
      _polyLines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routPoints,
          color: Colors.green,
          jointType: JointType.round,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        centerTitle: true,
        title: const Text('Map Animation and Tracking'),
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              userLocation?.latitude ?? 25.0,
              userLocation?.longitude ?? 89.0,
            ),
            zoom: 16,
          ),
          onMapCreated: (GoogleMapController controller) {
            googleMapController = controller;
            listenCurrentLocation();
          },
          zoomGesturesEnabled: true,
          tiltGesturesEnabled: true,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          trafficEnabled: true,
          markers: _markers,
          polylines: _polyLines,
          compassEnabled: true,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (userLocation != null) {
            googleMapController.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(
                  userLocation!.latitude,
                  userLocation!.longitude,
                ),
                16,
              ),
            );
          }
        },
        child: const Icon(Icons.person),
      ),
    );
  }

  @override
  void dispose() {
    googleMapController.dispose();
    super.dispose();
  }
}
