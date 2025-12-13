import 'package:flutter_test/flutter_test.dart';
import 'package:emergenccy_communication/services/network_failure_simulator.dart';

void main() {
  group('Network Failure Simulator Tests', () {
    late NetworkFailureSimulator simulator;

    setUp(() {
      simulator = NetworkFailureSimulator.instance;
      simulator.reset();
    });

    test('Should be disabled by default', () {
      expect(simulator.isEnabled, false);
      expect(simulator.failureRate, 0.0);
    });

    test('Should enable/disable simulation', () {
      simulator.setEnabled(true);
      expect(simulator.isEnabled, true);
      
      simulator.setEnabled(false);
      expect(simulator.isEnabled, false);
    });

    test('Should set failure rate correctly', () {
      simulator.setFailureRate(0.5);
      expect(simulator.failureRate, 0.5);
      
      simulator.setFailureRate(1.5); // Should clamp to 1.0
      expect(simulator.failureRate, 1.0);
      
      simulator.setFailureRate(-0.5); // Should clamp to 0.0
      expect(simulator.failureRate, 0.0);
    });

    test('Should simulate connection failures when enabled', () async {
      simulator.setEnabled(true);
      simulator.setFailureRate(1.0); // 100% failure rate
      simulator.setSimulateConnectionDrops(true);
      
      final shouldFail = await simulator.simulateConnectionFailure();
      expect(shouldFail, true);
    });

    test('Should not simulate failures when disabled', () async {
      simulator.setEnabled(false);
      simulator.setFailureRate(1.0);
      simulator.setSimulateConnectionDrops(true);
      
      final shouldFail = await simulator.simulateConnectionFailure();
      expect(shouldFail, false);
    });

    test('Should simulate message loss when enabled', () async {
      simulator.setEnabled(true);
      simulator.setFailureRate(1.0);
      simulator.setSimulateMessageLoss(true);
      
      final shouldLose = await simulator.simulateMessageLoss();
      expect(shouldLose, true);
    });

    test('Should add network delay when enabled', () async {
      simulator.setEnabled(true);
      simulator.setFailureRate(1.0);
      simulator.setSimulateSlowNetwork(true);
      
      final stopwatch = Stopwatch()..start();
      await simulator.simulateNetworkDelay();
      stopwatch.stop();
      
      // Should have added some delay (at least 500ms)
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(500));
    });

    test('Should reset all settings', () {
      simulator.setEnabled(true);
      simulator.setFailureRate(0.8);
      simulator.setSimulateConnectionDrops(true);
      
      simulator.reset();
      
      expect(simulator.isEnabled, false);
      expect(simulator.failureRate, 0.0);
    });

    test('Should return correct settings', () {
      simulator.setEnabled(true);
      simulator.setFailureRate(0.6);
      simulator.setSimulateMessageLoss(true);
      
      final settings = simulator.getSettings();
      
      expect(settings['isEnabled'], true);
      expect(settings['failureRate'], 0.6);
      expect(settings['simulateMessageLoss'], true);
    });
  });
}

