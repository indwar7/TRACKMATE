import 'dart:math';

class TravelModeDetector {
  // Speed thresholds in m/s (meters per second)
  static const double _walkingMaxSpeed = 2.0; // ~7 km/h
  static const double _bicycleMaxSpeed = 8.0; // ~29 km/h
  static const double _autoMaxSpeed = 14.0; // ~50 km/h
  static const double _bikeMaxSpeed = 22.0; // ~79 km/h
  static const double _carMaxSpeed = 35.0; // ~126 km/h
  static const double _busMaxSpeed = 25.0; // ~90 km/h
  static const double _trainMaxSpeed = 55.0; // ~198 km/h

  // Speed analysis window
  final List<SpeedSample> _speedSamples = [];
  final int _maxSamples = 20; // Keep last 20 samples

  // Mode tracking
  final Map<String, int> _modeFrequency = {};

  /// Add a new speed sample from GPS
  void addSpeedSample(double speedMps, double accuracy) {
    // Only consider samples with reasonable accuracy (< 50m)
    if (accuracy > 50) return;

    _speedSamples.add(SpeedSample(
      speed: speedMps,
      timestamp: DateTime.now(),
      accuracy: accuracy,
    ));

    // Keep only recent samples
    if (_speedSamples.length > _maxSamples) {
      _speedSamples.removeAt(0);
    }

    // Update mode frequency
    final mode = _detectModeFromSpeed(speedMps);
    _modeFrequency[mode] = (_modeFrequency[mode] ?? 0) + 1;
  }

  /// Detect mode from a single speed value
  String _detectModeFromSpeed(double speedMps) {
    if (speedMps < 0.5) return 'Stationary';
    if (speedMps <= _walkingMaxSpeed) return 'Walking';
    if (speedMps <= _bicycleMaxSpeed) return 'Bicycle';
    if (speedMps <= _autoMaxSpeed) return 'Auto Rickshaw';
    if (speedMps <= _bikeMaxSpeed) return 'Motorcycle';
    if (speedMps <= _busMaxSpeed) return 'Bus';
    if (speedMps <= _carMaxSpeed) return 'Car - Petrol'; // Default to petrol
    if (speedMps <= _trainMaxSpeed) return 'Train';
    return 'Car - Petrol'; // High speed default
  }

  /// Get the most likely travel mode based on collected samples
  String getPredictedMode() {
    if (_speedSamples.isEmpty) return 'Car - Petrol';

    // Calculate statistics
    final speeds = _speedSamples.map((s) => s.speed).toList();
    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
    final medianSpeed = _calculateMedian(speeds);

    // Get most frequent mode
    String mostFrequentMode = _getMostFrequentMode();

    // Special cases
    if (maxSpeed < 1.0 && avgSpeed < 0.5) {
      return 'Walking'; // Very slow movement
    }

    // Use median speed for more stable detection
    final modeFromMedian = _detectModeFromSpeed(medianSpeed);

    // If max speed suggests a different mode (e.g., bus vs car), use frequency
    if (_isSignificantSpeedVariation(speeds)) {
      // High variation suggests stop-and-go traffic (Bus, Auto)
      if (maxSpeed <= _busMaxSpeed && avgSpeed <= _autoMaxSpeed) {
        return 'Bus';
      }
    }

    // Combine median-based detection with frequency
    if (mostFrequentMode == modeFromMedian) {
      return mostFrequentMode;
    }

    // Default to median-based detection
    return modeFromMedian;
  }

  /// Get detailed mode analysis
  Map<String, dynamic> getModeAnalysis() {
    if (_speedSamples.isEmpty) {
      return {
        'predicted_mode': 'Car - Petrol',
        'confidence': 'Low',
        'avg_speed_kmh': 0.0,
        'max_speed_kmh': 0.0,
        'samples_count': 0,
      };
    }

    final speeds = _speedSamples.map((s) => s.speed).toList();
    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
    final maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
    final medianSpeed = _calculateMedian(speeds);

    final predictedMode = getPredictedMode();
    final confidence = _calculateConfidence(speeds, predictedMode);

    return {
      'predicted_mode': predictedMode,
      'confidence': confidence,
      'avg_speed_kmh': (avgSpeed * 3.6).toStringAsFixed(1),
      'max_speed_kmh': (maxSpeed * 3.6).toStringAsFixed(1),
      'median_speed_kmh': (medianSpeed * 3.6).toStringAsFixed(1),
      'samples_count': _speedSamples.length,
      'mode_frequency': Map.from(_modeFrequency),
    };
  }

  /// Calculate confidence level
  String _calculateConfidence(List<double> speeds, String predictedMode) {
    if (speeds.length < 5) return 'Low';

    final modeFreq = _modeFrequency[predictedMode] ?? 0;
    final totalSamples = _speedSamples.length;
    final consistency = modeFreq / totalSamples;

    if (consistency >= 0.7) return 'High';
    if (consistency >= 0.5) return 'Medium';
    return 'Low';
  }

  /// Get most frequent mode
  String _getMostFrequentMode() {
    if (_modeFrequency.isEmpty) return 'Car - Petrol';

    String mostFrequent = _modeFrequency.keys.first;
    int maxCount = 0;

    _modeFrequency.forEach((mode, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = mode;
      }
    });

    return mostFrequent;
  }

  /// Calculate median of speeds
  double _calculateMedian(List<double> speeds) {
    final sorted = List<double>.from(speeds)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    }
  }

  /// Check if there's significant speed variation (stop-and-go pattern)
  bool _isSignificantSpeedVariation(List<double> speeds) {
    if (speeds.length < 5) return false;

    final avg = speeds.reduce((a, b) => a + b) / speeds.length;
    final variance = speeds.map((s) => pow(s - avg, 2)).reduce((a, b) => a + b) / speeds.length;
    final stdDev = sqrt(variance);

    // High standard deviation relative to mean suggests stop-and-go
    return (stdDev / (avg + 0.1)) > 0.6;
  }

  /// Reset detector
  void reset() {
    _speedSamples.clear();
    _modeFrequency.clear();
  }

  /// Convert speed from m/s to km/h
  static double mpsToKmh(double mps) {
    return mps * 3.6;
  }

  /// Convert speed from km/h to m/s
  static double kmhToMps(double kmh) {
    return kmh / 3.6;
  }
}

class SpeedSample {
  final double speed;
  final DateTime timestamp;
  final double accuracy;

  SpeedSample({
    required this.speed,
    required this.timestamp,
    required this.accuracy,
  });
}