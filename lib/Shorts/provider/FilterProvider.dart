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

  void setBasicVideoCategory(String? region, String? category, String? price) {

    double? priceToDouble;

    if (price != null) {
      switch (price) {
        case '1만원 미만' :
          priceToDouble = 10;
          break;
        case '1~2만원' :
          priceToDouble = 20;
          break;
        case '2만원 이상' :
          priceToDouble = 50;
          break;
        default :
          priceToDouble = 50;
          break;

      }
    }

    filterRegion = region;
    filterCategory = category;
    filterPrice = priceToDouble;

    print('$filterRegion + $filterCategory + $filterPrice');

    notifyListeners();
  }

  Future<void> setNearVideoCategory(String? category, String? price,) async {

    final position = await Geolocator.getCurrentPosition();

    double? priceToDouble;

    if (price != null) {
      switch (price) {
        case '1만원 미만' :
          priceToDouble = 10;
          break;
        case '1~2만원' :
          priceToDouble = 20;
          break;
        case '2만원 이상' :
          priceToDouble = 50;
          break;
        default :
          priceToDouble = 50;
          break;

      }
    }

    filterLat = position.latitude;
    filterLon = position.longitude;
    filterRegion = null;
    filterCategory = category;
    filterPrice = priceToDouble;
    filterByDistance = true;

    notifyListeners();

  }
}
