import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:uber/requests/google_maps_requests.dart';

class AppState with ChangeNotifier{
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: "AIzaSyATo3rxVw0WxWxXnxeirWRoz-LBbO72vOQ");
  static LatLng _initialPosition;
  LatLng _lastPosition = _initialPosition;
  bool locationsServiceActive = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  GoogleMapController _mapController;
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  TextEditingController locationController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  LatLng get initialPosition => _initialPosition;
  LatLng get lastPosition => _lastPosition;
  GoogleMapsServices get googleMapsServices => _googleMapsServices;
  GoogleMapController get mapController => _mapController;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polyLines => _polyLines;

  AppState(){
    _getUserLocation();
    _loadingInitialPosition();
  }

  /*사용자 위치 가져오기*/
  void _getUserLocation() async {
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
      _initialPosition = LatLng(position.latitude, position.longitude);
      locationController.text = placemark[0].name;
      notifyListeners();
  }

  /*라우트 생성성*/
  void createRoute(String encondedPoly) {
      _polyLines.add(Polyline(polylineId:  PolylineId(_lastPosition.toString()),
          width: 10,
          points: _convertToLatLng(_decodePoly(encondedPoly)),
          color: Colors.black));
      notifyListeners();
  }

  /*지도에 위치 표시 추가*/
  void _addMarker(LatLng location, String address) {
      _markers.add(Marker(markerId: MarkerId(_lastPosition.toString()),
          position: location,
          infoWindow: InfoWindow(
              title: address,
              snippet: "go here"
          ),
          icon: BitmapDescriptor.defaultMarker
      ));
      notifyListeners();
  }

  /*LAGLNG 리스트 생성*/
  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for(int i = 0; i < points.length; i++) {
      if(i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;

    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);

      if(result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for(var i = 2; i < lList.length; i++)
      lList[i] += lList[i-2];

    print(lList.toString());

    return lList;
  }

  void sendRequest(String intendedLocation) async {
    List<Placemark> placemark = await Geolocator().placemarkFromAddress(intendedLocation);
    double latitude = placemark[0].position.latitude;
    double longitude = placemark[0].position.longitude;
    LatLng destination = LatLng(latitude, longitude);
    _addMarker(destination, intendedLocation);
    String route = await _googleMapsServices.getRouteCoordinates(_initialPosition, destination);
    createRoute(route);
    notifyListeners();
  }

  void onCameraMove(CameraPosition position) {
      _lastPosition = position.target;
      notifyListeners();
  }


  void onCreated(GoogleMapController controller) {
      _mapController = controller;
      notifyListeners();
  }

  void _loadingInitialPosition() async {
    await Future.delayed(Duration(seconds: 3)).then((v) {
      if(_initialPosition == null) {
        locationsServiceActive = false;
        notifyListeners();
      }
    });
  }

  Future<Null> displayPrediction(Prediction p) async {
    if (p != null) {
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);

      print(detail.result.name);

      var placeId = p.placeId;
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;

      var address = await Geocoder.local.findAddressesFromQuery(p.description);

      destinationController.text = detail.result.name;
      _lastPosition = LatLng(detail.result.geometry.location.lat, detail.result.geometry.location.lng);

      print(lat);
      print(lng);
    }
  }
}