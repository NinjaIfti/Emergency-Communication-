import 'dart:math';

class NetworkFailureSimulator {
  static final NetworkFailureSimulator instance = NetworkFailureSimulator._init();
  
  NetworkFailureSimulator._init();

  bool _isEnabled = false;
  double _failureRate = 0.0; // 0.0 to 1.0 (0% to 100%)
  bool _simulateConnectionDrops = false;
  bool _simulateMessageLoss = false;
  bool _simulateSlowNetwork = false;
  
  final Random _random = Random();

  // Enable/disable simulation
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    print('Network failure simulation ${enabled ? "enabled" : "disabled"}');
  }

  bool get isEnabled => _isEnabled;

  // Set failure rate (0.0 to 1.0)
  void setFailureRate(double rate) {
    _failureRate = rate.clamp(0.0, 1.0);
    print('Network failure rate set to ${(_failureRate * 100).toStringAsFixed(1)}%');
  }

  double get failureRate => _failureRate;

  // Enable/disable specific failure types
  void setSimulateConnectionDrops(bool enabled) {
    _simulateConnectionDrops = enabled;
  }

  void setSimulateMessageLoss(bool enabled) {
    _simulateMessageLoss = enabled;
  }

  void setSimulateSlowNetwork(bool enabled) {
    _simulateSlowNetwork = enabled;
  }

  // Simulate connection failure
  Future<bool> simulateConnectionFailure() async {
    if (!_isEnabled || !_simulateConnectionDrops) {
      return false; // No failure
    }

    if (_random.nextDouble() < _failureRate) {
      print('SIMULATED: Connection failure');
      return true; // Simulated failure
    }

    return false;
  }

  // Simulate message loss
  Future<bool> simulateMessageLoss() async {
    if (!_isEnabled || !_simulateMessageLoss) {
      return false; // No loss
    }

    if (_random.nextDouble() < _failureRate) {
      print('SIMULATED: Message loss');
      return true; // Simulated loss
    }

    return false;
  }

  // Simulate slow network (add delay)
  Future<void> simulateNetworkDelay() async {
    if (!_isEnabled || !_simulateSlowNetwork) {
      return;
    }

    if (_random.nextDouble() < _failureRate) {
      final delay = _random.nextInt(2000) + 500; // 500-2500ms delay
      print('SIMULATED: Network delay of ${delay}ms');
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  // Simulate random network failure
  Future<bool> shouldFail() async {
    if (!_isEnabled) {
      return false;
    }

    return _random.nextDouble() < _failureRate;
  }

  // Reset all simulation settings
  void reset() {
    _isEnabled = false;
    _failureRate = 0.0;
    _simulateConnectionDrops = false;
    _simulateMessageLoss = false;
    _simulateSlowNetwork = false;
    print('Network failure simulation reset');
  }

  // Get current simulation settings
  Map<String, dynamic> getSettings() {
    return {
      'isEnabled': _isEnabled,
      'failureRate': _failureRate,
      'simulateConnectionDrops': _simulateConnectionDrops,
      'simulateMessageLoss': _simulateMessageLoss,
      'simulateSlowNetwork': _simulateSlowNetwork,
    };
  }
}

