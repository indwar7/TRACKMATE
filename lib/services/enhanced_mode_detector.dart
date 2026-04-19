import 'dart:math';
import 'package:flutter/foundation.dart';

/// Enhanced travel mode detector using multiple sensor data and ML-like algorithms
class EnhancedTravelModeDetector {
  // Speed samples buffer with timestamps
  final List<SpeedSample> _speedSamples = [];
  final List<AccelerationSample> _accelerationSamples = [];

  // Window sizes for analysis
  static const int _speedWindowSize = 20; // 20 samples
  static const int _accelWindowSize = 30; // 30 samples
  static const int _minSamplesForPrediction = 10;

  // Mode detection thresholds (km/h)
  static const Map<String, SpeedRange> _modeSpeedRanges = {
    'Stationary': SpeedRange(0, 3),
    'Walking': SpeedRange(2, 8),
    'Running': SpeedRange(7, 15),
    'Bicycle': SpeedRange(10, 30),
    'Motorcycle': SpeedRange(15, 120),
    'Car': SpeedRange(20, 150),
    'Bus': SpeedRange(15, 80),
    'Train': SpeedRange(30, 200),
  };

  // Movement pattern characteristics
  final Map<String, int> _modeVotes = {};
  String _currentMode = 'Stationary';
  String _confidence = 'Low';

  // For detecting stop-and-go patterns (reserved for future use)

  // Statistical features
  double _speedMean = 0.0;
  double _speedStdDev = 0.0;
  double _speedVariance = 0.0;
  double _speedMax = 0.0;
  double _speedMedian = 0.0;

  // Acceleration features
  double _accelMean = 0.0;
  double _accelStdDev = 0.0;
  double _jerkiness = 0.0; // Rate of acceleration change

  // Movement continuity
  double _movementSmoothness = 0.0;

  /// Add speed sample with accuracy
  void addSpeedSample(double speedMs, double accuracy, {double? bearing}) {
    final speedKmh = speedMs * 3.6;
    final sample = SpeedSample(
      speedKmh: speedKmh,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      bearing: bearing,
    );

    _speedSamples.add(sample);

    // Keep only recent samples
    if (_speedSamples.length > _speedWindowSize) {
      _speedSamples.removeAt(0);
    }

    // Calculate acceleration from speed changes
    if (_speedSamples.length >= 2) {
      final prev = _speedSamples[_speedSamples.length - 2];
      final curr = _speedSamples.last;
      final timeDiff = curr.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;

      if (timeDiff > 0) {
        final accel = (curr.speedKmh - prev.speedKmh) / 3.6 / timeDiff; // m/s²
        addAccelerationSample(accel, curr.timestamp);
      }
    }

    _analyzeSamples();
  }

  /// Add acceleration sample
  void addAccelerationSample(double acceleration, DateTime timestamp) {
    _accelerationSamples.add(AccelerationSample(
      acceleration: acceleration,
      timestamp: timestamp,
    ));

    if (_accelerationSamples.length > _accelWindowSize) {
      _accelerationSamples.removeAt(0);
    }
  }

  /// Analyze samples and predict mode
  void _analyzeSamples() {
    if (_speedSamples.length < _minSamplesForPrediction) {
      _currentMode = 'Initializing...';
      _confidence = 'Low';
      return;
    }

    // Calculate statistical features
    _calculateSpeedStatistics();
    _calculateAccelerationStatistics();
    _calculateMovementPatterns();

    // Multi-factor voting system
    _modeVotes.clear();

    // Factor 1: Speed-based voting (30% weight)
    _voteBySpeed();

    // Factor 2: Acceleration pattern voting (25% weight)
    _voteByAcceleration();

    // Factor 3: Speed variance voting (20% weight)
    _voteBySpeedVariance();

    // Factor 4: Stop-and-go pattern (15% weight)
    _voteByStopGoPattern();

    // Factor 5: Movement smoothness (10% weight)
    _voteBySmoothness();

    // Determine winner
    _determineMode();
  }

  void _calculateSpeedStatistics() {
    if (_speedSamples.isEmpty) return;

    final speeds = _speedSamples.map((s) => s.speedKmh).toList();

    // Mean
    _speedMean = speeds.reduce((a, b) => a + b) / speeds.length;

    // Variance and Std Dev
    _speedVariance = speeds.map((s) => pow(s - _speedMean, 2)).reduce((a, b) => a + b) / speeds.length;
    _speedStdDev = sqrt(_speedVariance);

    // Max
    _speedMax = speeds.reduce(max);

    // Median
    final sorted = List<double>.from(speeds)..sort();
    if (sorted.length % 2 == 0) {
      _speedMedian = (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
    } else {
      _speedMedian = sorted[sorted.length ~/ 2];
    }
  }

  void _calculateAccelerationStatistics() {
    if (_accelerationSamples.length < 3) return;

    final accels = _accelerationSamples.map((a) => a.acceleration).toList();

    // Mean acceleration
    _accelMean = accels.reduce((a, b) => a + b) / accels.length;

    // Std dev of acceleration
    final variance = accels.map((a) => pow(a - _accelMean, 2)).reduce((a, b) => a + b) / accels.length;
    _accelStdDev = sqrt(variance);

    // Jerkiness (rate of change of acceleration)
    double totalJerk = 0;
    for (int i = 1; i < _accelerationSamples.length; i++) {
      final timeDiff = _accelerationSamples[i].timestamp
          .difference(_accelerationSamples[i - 1].timestamp)
          .inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        final jerk = (_accelerationSamples[i].acceleration -
            _accelerationSamples[i - 1].acceleration).abs() / timeDiff;
        totalJerk += jerk;
      }
    }
    _jerkiness = totalJerk / (_accelerationSamples.length - 1);
  }

  void _calculateMovementPatterns() {
    if (_speedSamples.length < 5) return;

    // Detect direction changes (for bearing data)
    int directionChanges = 0;
    for (int i = 2; i < _speedSamples.length; i++) {
      final prev = _speedSamples[i - 1].bearing;
      final curr = _speedSamples[i].bearing;

      if (prev != null && curr != null) {
        final diff = (curr - prev).abs();
        // Significant direction change > 30 degrees
        if (diff > 30 && diff < 330) {
          directionChanges++;
        }
      }
    }
    _movementSmoothness = directionChanges > 0
        ? 1.0 / directionChanges
        : 1.0;

    // Movement smoothness (inverse of speed coefficient of variation)
    if (_speedMean > 0) {
      _movementSmoothness = 1.0 - (_speedStdDev / _speedMean).clamp(0, 1);
    }
  }

  void _voteBySpeed() {
    // Use median speed instead of mean (more robust to outliers)
    final speed = _speedMedian;

    for (final entry in _modeSpeedRanges.entries) {
      if (speed >= entry.value.min && speed <= entry.value.max) {
        _modeVotes[entry.key] = (_modeVotes[entry.key] ?? 0) + 30;
      }
    }
  }

  void _voteByAcceleration() {
    // Different modes have different acceleration characteristics

    // Stationary: very low acceleration variance
    if (_accelStdDev < 0.5 && _speedMean < 2) {
      _modeVotes['Stationary'] = (_modeVotes['Stationary'] ?? 0) + 25;
    }

    // Walking/Running: moderate, rhythmic acceleration (periodic)
    if (_accelStdDev > 0.3 && _accelStdDev < 2.0 && _speedMean < 15) {
      if (_speedMean < 8) {
        _modeVotes['Walking'] = (_modeVotes['Walking'] ?? 0) + 20;
      } else {
        _modeVotes['Running'] = (_modeVotes['Running'] ?? 0) + 20;
      }
    }

    // Bicycle: moderate acceleration with medium jerkiness
    if (_accelStdDev > 0.5 && _accelStdDev < 3.0 &&
        _jerkiness > 0.3 && _jerkiness < 2.0 &&
        _speedMean > 8 && _speedMean < 35) {
      _modeVotes['Bicycle'] = (_modeVotes['Bicycle'] ?? 0) + 25;
    }

    // Motorcycle: higher acceleration, higher jerkiness
    if (_accelStdDev > 1.5 && _jerkiness > 1.0 &&
        _speedMean > 12 && _speedMax > 40) {
      _modeVotes['Motorcycle'] = (_modeVotes['Motorcycle'] ?? 0) + 25;
    }

    // Car: smooth acceleration, moderate variance
    if (_accelStdDev > 0.8 && _accelStdDev < 3.5 &&
        _speedMean > 20 && _speedMax > 40) {
      _modeVotes['Car'] = (_modeVotes['Car'] ?? 0) + 20;
    }
  }

  void _voteBySpeedVariance() {
    // Different modes have different speed consistency

    final cv = _speedMean > 0 ? _speedStdDev / _speedMean : 0; // Coefficient of variation

    // Stationary: very low variance
    if (cv < 0.2 && _speedMean < 3) {
      _modeVotes['Stationary'] = (_modeVotes['Stationary'] ?? 0) + 20;
    }

    // Walking: moderate variance (pedestrians vary speed)
    if (cv > 0.2 && cv < 0.6 && _speedMean < 10) {
      _modeVotes['Walking'] = (_modeVotes['Walking'] ?? 0) + 15;
    }

    // Bicycle: higher variance (coasting, pedaling)
    if (cv > 0.3 && cv < 0.8 && _speedMean > 8 && _speedMean < 35) {
      _modeVotes['Bicycle'] = (_modeVotes['Bicycle'] ?? 0) + 20;
    }

    // Motorized vehicles: lower variance (cruise control, consistent speeds)
    if (cv < 0.4 && _speedMean > 25) {
      _modeVotes['Car'] = (_modeVotes['Car'] ?? 0) + 15;
      _modeVotes['Motorcycle'] = (_modeVotes['Motorcycle'] ?? 0) + 15;
    }

    // Bus/Train: very consistent speed
    if (cv < 0.25 && _speedMean > 30 && _speedMean < 90) {
      _modeVotes['Bus'] = (_modeVotes['Bus'] ?? 0) + 20;
    }
  }

  void _voteByStopGoPattern() {
    // Count stops and starts in the window
    int stops = 0;
    int moves = 0;

    for (final sample in _speedSamples) {
      if (sample.speedKmh < 3) {
        stops++;
      } else {
        moves++;
      }
    }

    final stopRatio = stops / _speedSamples.length;

    // Bus: frequent stops
    if (stopRatio > 0.3 && stopRatio < 0.6 && _speedMax > 30) {
      _modeVotes['Bus'] = (_modeVotes['Bus'] ?? 0) + 15;
    }

    // Car in traffic: some stops
    if (stopRatio > 0.15 && stopRatio < 0.45 && _speedMax > 25) {
      _modeVotes['Car'] = (_modeVotes['Car'] ?? 0) + 10;
    }

    // Bicycle: occasional stops
    if (stopRatio > 0.1 && stopRatio < 0.4 && _speedMean > 8 && _speedMean < 30) {
      _modeVotes['Bicycle'] = (_modeVotes['Bicycle'] ?? 0) + 15;
    }

    // Walking: can have many stops
    if (stopRatio > 0.2 && _speedMean < 8) {
      _modeVotes['Walking'] = (_modeVotes['Walking'] ?? 0) + 10;
    }
  }

  void _voteBySmoothness() {
    // Smooth movement = motorized vehicles on good roads
    // Jerky movement = walking, cycling, or traffic

    if (_movementSmoothness > 0.7 && _speedMean > 30) {
      _modeVotes['Car'] = (_modeVotes['Car'] ?? 0) + 10;
      _modeVotes['Train'] = (_modeVotes['Train'] ?? 0) + 10;
    }

    if (_movementSmoothness < 0.5 && _speedMean < 10) {
      _modeVotes['Walking'] = (_modeVotes['Walking'] ?? 0) + 8;
    }

    if (_movementSmoothness < 0.6 && _speedMean > 10 && _speedMean < 30) {
      _modeVotes['Bicycle'] = (_modeVotes['Bicycle'] ?? 0) + 10;
    }
  }

  void _determineMode() {
    if (_modeVotes.isEmpty) {
      _currentMode = 'Unknown';
      _confidence = 'Low';
      return;
    }

    // Find winner
    final sorted = _modeVotes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final winner = sorted.first;
    final totalVotes = _modeVotes.values.reduce((a, b) => a + b);
    final winnerPercentage = (winner.value / totalVotes * 100).round();

    _currentMode = winner.key;

    // Determine confidence based on vote percentage
    if (winnerPercentage >= 60) {
      _confidence = 'High';
    } else if (winnerPercentage >= 40) {
      _confidence = 'Medium';
    } else {
      _confidence = 'Low';
    }

    // Apply contextual rules to improve accuracy
    _applyContextualRules();

    debugPrint('🎯 Mode Detection: $_currentMode ($winnerPercentage% - $_confidence)');
    debugPrint('   Speed: ${_speedMean.toStringAsFixed(1)} km/h (σ=${_speedStdDev.toStringAsFixed(1)})');
    debugPrint('   Accel: σ=${_accelStdDev.toStringAsFixed(2)} m/s², Jerk=${_jerkiness.toStringAsFixed(2)}');
    debugPrint('   Votes: ${_modeVotes.toString()}');
  }

  void _applyContextualRules() {
    // Rule 1: Very low speed + low variance = definitely not motorized
    if (_speedMean < 5 && _speedStdDev < 2) {
      if (_currentMode == 'Car' || _currentMode == 'Motorcycle' || _currentMode == 'Bus') {
        _currentMode = _speedMean < 2 ? 'Stationary' : 'Walking';
        _confidence = 'High';
      }
    }

    // Rule 2: High speed + high smoothness = motorized vehicle
    if (_speedMean > 40 && _movementSmoothness > 0.6) {
      if (_currentMode == 'Walking' || _currentMode == 'Bicycle') {
        _currentMode = 'Car';
        _confidence = 'Medium';
      }
    }

    // Rule 3: Bike speed range with low jerkiness
    if (_speedMean > 12 && _speedMean < 25 && _jerkiness < 1.5 && _accelStdDev < 2.5) {
      if (_confidence == 'Low' || _currentMode == 'Walking') {
        _currentMode = 'Bicycle';
        _confidence = 'Medium';
      }
    }

    // Rule 4: Motorcycle acceleration signature
    if (_speedMax > 50 && _accelStdDev > 2.0 && _jerkiness > 1.5) {
      if (_speedMean > 20) {
        _currentMode = 'Motorcycle';
        _confidence = 'High';
      }
    }
  }

  /// Get current mode analysis
  Map<String, dynamic> getModeAnalysis() {
    return {
      'predicted_mode': _currentMode,
      'confidence': _confidence,
      'speed_mean': _speedMean.toStringAsFixed(1),
      'speed_median': _speedMedian.toStringAsFixed(1),
      'speed_std_dev': _speedStdDev.toStringAsFixed(1),
      'speed_max': _speedMax.toStringAsFixed(1),
      'accel_std_dev': _accelStdDev.toStringAsFixed(2),
      'jerkiness': _jerkiness.toStringAsFixed(2),
      'smoothness': _movementSmoothness.toStringAsFixed(2),
      'samples': _speedSamples.length,
      'votes': _modeVotes.toString(),
    };
  }

  /// Reset detector
  void reset() {
    _speedSamples.clear();
    _accelerationSamples.clear();
    _modeVotes.clear();
    _currentMode = 'Stationary';
    _confidence = 'Low';
  }
}

class SpeedSample {
  final double speedKmh;
  final double accuracy;
  final DateTime timestamp;
  final double? bearing;

  SpeedSample({
    required this.speedKmh,
    required this.accuracy,
    required this.timestamp,
    this.bearing,
  });
}

class AccelerationSample {
  final double acceleration;
  final DateTime timestamp;

  AccelerationSample({
    required this.acceleration,
    required this.timestamp,
  });
}

class SpeedRange {
  final double min;
  final double max;

  const SpeedRange(this.min, this.max);
}