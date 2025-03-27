import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier{

  String? filterRegion;
  String? filterCategory;
  double? filterPrice;

  void setVideoCategory(String? region, String? category, double? price){

    filterRegion = region;
    filterCategory = category;
    filterPrice = price;

    notifyListeners();

  }

}