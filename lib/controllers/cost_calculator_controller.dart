import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CostCalculatorController extends GetxController {
  // Text Controllers
  final startLocationController = TextEditingController();
  final endLocationController = TextEditingController();
  final distanceController = TextEditingController();
  final companionsController = TextEditingController(text: '1');
  final fuelPriceController = TextEditingController();
  final averageController = TextEditingController();
  final parkingCostController = TextEditingController(text: '0');
  final tollCostController = TextEditingController(text: '0');

  // Observable values
  final modeOfTravel = 'Car'.obs;
  final fuelType = 'Petrol'.obs;
  final isCalculated = false.obs;

  // Results
  final RxDouble totalCost = 0.0.obs;
  final RxDouble perPersonCost = 0.0.obs;
  final RxDouble co2Emission = 0.0.obs;

  // Comparison costs
  final RxDouble carCost = 0.0.obs;
  final RxDouble bikeCost = 0.0.obs;
  final RxDouble airplaneCost = 0.0.obs;
  final RxDouble trainCost = 0.0.obs;
  final RxDouble cabCost = 0.0.obs;

  @override
  void onClose() {
    startLocationController.dispose();
    endLocationController.dispose();
    distanceController.dispose();
    companionsController.dispose();
    fuelPriceController.dispose();
    averageController.dispose();
    parkingCostController.dispose();
    tollCostController.dispose();
    super.onClose();
  }

  // Calculate cost (you can integrate with your API here)
  void calculateCost() {
    // Validate inputs
    if (startLocationController.text.isEmpty ||
        endLocationController.text.isEmpty ||
        distanceController.text.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Parse values
    final distance = double.tryParse(distanceController.text) ?? 0;
    final companions = int.tryParse(companionsController.text) ?? 1;
    final fuelPrice = double.tryParse(fuelPriceController.text) ?? 0;
    final average = double.tryParse(averageController.text) ?? 15;
    final parking = double.tryParse(parkingCostController.text) ?? 0;
    final toll = double.tryParse(tollCostController.text) ?? 0;

    // Calculate based on mode
    _calculateForAllModes(distance, companions, fuelPrice, average, parking, toll);

    // Set the main cost based on selected mode
    switch (modeOfTravel.value) {
      case 'Car':
        totalCost.value = carCost.value;
        break;
      case 'Bike':
        totalCost.value = bikeCost.value;
        break;
      case 'Airplane':
        totalCost.value = airplaneCost.value;
        break;
      case 'Train':
        totalCost.value = trainCost.value;
        break;
      default:
        totalCost.value = carCost.value;
    }

    perPersonCost.value = totalCost.value / companions;

    // Calculate CO2 emission (kg CO2 per km varies by vehicle)
    co2Emission.value = _calculateCO2(distance);

    isCalculated.value = true;
  }

  void _calculateForAllModes(double distance, int companions, double fuelPrice,
      double average, double parking, double toll) {
    // Car calculation
    final fuelNeeded = distance / average;
    final fuelCost = fuelNeeded * fuelPrice;
    carCost.value = (fuelCost + parking + toll) / companions;

    // Bike calculation (assuming 40 km/l average)
    final bikeFuelNeeded = distance / 40;
    final bikeFuelCost = bikeFuelNeeded * fuelPrice;
    bikeCost.value = (bikeFuelCost + toll) / companions;

    // Airplane calculation (approximate ₹4-6 per km)
    airplaneCost.value = (distance * 5) / companions;

    // Train calculation (approximate ₹0.5-1 per km)
    trainCost.value = (distance * 0.7) / companions;

    // Hired cab (approximate ₹12-15 per km)
    cabCost.value = (distance * 13) / companions;
  }

  double _calculateCO2(double distance) {
    // CO2 emission factors (kg CO2 per km)
    const Map<String, double> emissionFactors = {
      'Car': 0.12, // Petrol car
      'Bike': 0.06,
      'Bus': 0.04,
      'Train': 0.03,
      'Airplane': 0.25,
      'Bi-cycle': 0.0,
      'Walk': 0.0,
    };

    // Adjust for fuel type
    double factor = emissionFactors[modeOfTravel.value] ?? 0.12;

    if (fuelType.value == 'Diesel') {
      factor *= 1.15; // Diesel produces ~15% more CO2
    } else if (fuelType.value == 'Electric') {
      factor *= 0.3; // Electric is much cleaner
    }

    return distance * factor;
  }

  // API Integration (Optional - replace dummy calculation)
  Future<void> calculateWithAPI() async {
    try {
      final response = await http.post(
        Uri.parse('YOUR_API_ENDPOINT/calculate-cost'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'from': startLocationController.text,
          'to': endLocationController.text,
          'distance': distanceController.text,
          'mode': modeOfTravel.value,
          'companions': companionsController.text,
          'fuel_price': fuelPriceController.text,
          'fuel_type': fuelType.value,
          'average': averageController.text,
          'parking': parkingCostController.text,
          'toll': tollCostController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        totalCost.value = data['total_cost'];
        perPersonCost.value = data['per_person_cost'];
        co2Emission.value = data['co2_emission'];
        carCost.value = data['car_cost'];
        bikeCost.value = data['bike_cost'];
        airplaneCost.value = data['airplane_cost'];
        trainCost.value = data['train_cost'];
        cabCost.value = data['cab_cost'];
        isCalculated.value = true;
      }
    } catch (e) {
      debugPrint('API Error: $e');
      // Fallback to local calculation
      calculateCost();
    }
  }

  void reset() {
    isCalculated.value = false;
    startLocationController.clear();
    endLocationController.clear();
    distanceController.clear();
    companionsController.text = '1';
    fuelPriceController.clear();
    averageController.clear();
    parkingCostController.text = '0';
    tollCostController.text = '0';
    modeOfTravel.value = 'Car';
    fuelType.value = 'Petrol';
  }
}