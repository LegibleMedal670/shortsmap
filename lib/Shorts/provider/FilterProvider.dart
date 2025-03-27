import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FilterProvider extends ChangeNotifier {
  String? filterRegion;
  String? filterCategory;
  double? filterPrice;
  double? filterLat;
  double? filterLon;
  double filterDistanceInKm = 1.5;
  bool filterByDistance = false;

  void setBasicVideoCategory(String? region, String? category, double? price) {

    filterRegion = region;
    filterCategory = category;
    filterPrice = price;

    notifyListeners();
  }

  Future<void> setNearVideoCategory(String? category, double? price,) async {

    final position = await Geolocator.getCurrentPosition();

    filterLat = position.latitude;
    filterLon = position.longitude;
    filterRegion = null;
    filterCategory = category;
    filterPrice = price;
    filterByDistance = true;

    notifyListeners();

  }
}
