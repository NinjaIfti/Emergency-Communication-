import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../utils/app_logger.dart';
import '../providers/message_provider.dart';
import '../providers/peer_provider.dart';
import '../services/mesh_network_service.dart';
import '../services/network_failure_simulator.dart';
import '../services/message_queue_service.dart';
import '../models/message_model.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LogLevel _selectedLogLevel = LogLevel.info;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Monitoring'),
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Messages', icon: Icon(Icons.message)),
            Tab(text: 'Network', icon: Icon(Icons.network_check)),
            Tab(text: 'Logs', icon: Icon(Icons.bug_report)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMessagesTab(),
          _buildNetworkTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<MessageProvider, PeerProvider>(
      builder: (context, messageProvider, peerProvider, child) {
        final meshService = MeshNetworkService.instance;
        final queueService = MessageQueueService.instance;
        final routingStats = meshService.getRoutingStats();
        final pendingCount = queueService.getPendingMessagesCount();

        return ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          children: [
            _buildStatCard(
              'Connection Status',
              '${peerProvider.connectedPeerCount} connected',
              Icons.bluetooth_connected,
              peerProvider.connectedPeerCount > 0 ? AppColors.success : AppColors.grey,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildStatCard(
              'Total Messages',
              '${messageProvider.messages.length}',
              Icons.message,
              AppColors.secondary,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildStatCard(
              'Pending Messages',
              '$pendingCount waiting for ACK',
              Icons.pending,
              AppColors.warning,
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            _buildStatCard(
              'Routing Table',
              '${routingStats['totalRoutes']} routes',
              Icons.route,
              AppColors.primary,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            _buildSectionTitle('System Status'),
            _buildInfoTile('Device ID', messageProvider.myDeviceId),
            _buildInfoTile('Total Peers', '${peerProvider.peers.length}'),
            _buildInfoTile('Scanning', peerProvider.isScanning ? 'Yes' : 'No'),
            FutureBuilder<int>(
              future: queueService.getQueueSize(),
              builder: (context, snapshot) {
                return _buildInfoTile('Queue Size', '${snapshot.data ?? 0}');
              },
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            _buildSectionTitle('Error Logs'),
            Consumer<MessageProvider>(
              builder: (context, provider, child) {
                final errorLogs = AppLogger.instance.getErrorLogs(limit: 5);
                if (errorLogs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.paddingMedium),
                      child: Text('No errors'),
                    ),
                  );
                }
                return Column(
                  children: errorLogs.map((log) => _buildLogEntry(log)).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        final messages = messageProvider.messages;
        final undelivered = messages.where((m) => !m.isDelivered).toList();

        return ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          children: [
            _buildSectionTitle('Message Statistics'),
            _buildInfoTile('Total Messages', '${messages.length}'),
            _buildInfoTile('Delivered', '${messages.where((m) => m.isDelivered).length}'),
            _buildInfoTile('Undelivered', '${undelivered.length}'),
            _buildInfoTile('SOS Messages', '${messages.where((m) => m.messageType == MessageType.SOS).length}'),
            const SizedBox(height: AppSizes.paddingMedium),
            if (undelivered.isNotEmpty) ...[
              _buildSectionTitle('Undelivered Messages'),
              ...undelivered.take(10).map((msg) => _buildMessageCard(msg)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNetworkTab() {
    final simulator = NetworkFailureSimulator.instance;
    final settings = simulator.getSettings();

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      children: [
        _buildSectionTitle('Network Failure Simulation'),
        SwitchListTile(
          title: const Text('Enable Simulation'),
          value: settings['isEnabled'] as bool,
          onChanged: (value) {
            simulator.setEnabled(value);
            setState(() {});
          },
        ),
        ListTile(
          title: Text('Failure Rate: ${((settings['failureRate'] as double) * 100).toStringAsFixed(1)}%'),
          subtitle: Slider(
            value: settings['failureRate'] as double,
            onChanged: (value) {
              simulator.setFailureRate(value);
              setState(() {});
            },
          ),
        ),
        SwitchListTile(
          title: const Text('Simulate Connection Drops'),
          value: settings['simulateConnectionDrops'] as bool,
          onChanged: (value) {
            simulator.setSimulateConnectionDrops(value);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text('Simulate Message Loss'),
          value: settings['simulateMessageLoss'] as bool,
          onChanged: (value) {
            simulator.setSimulateMessageLoss(value);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text('Simulate Slow Network'),
          value: settings['simulateSlowNetwork'] as bool,
          onChanged: (value) {
            simulator.setSimulateSlowNetwork(value);
            setState(() {});
          },
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        ElevatedButton(
          onPressed: () {
            simulator.reset();
            setState(() {});
          },
          child: const Text('Reset Simulation'),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        _buildSectionTitle('Network Statistics'),
        Consumer<PeerProvider>(
          builder: (context, peerProvider, child) {
            return Column(
              children: [
                _buildInfoTile('Connected Peers', '${peerProvider.connectedPeerCount}'),
                _buildInfoTile('Total Peers', '${peerProvider.peers.length}'),
                _buildInfoTile('Scanning', peerProvider.isScanning ? 'Active' : 'Inactive'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          color: AppColors.lightGrey,
          child: Row(
            children: [
              const Text('Log Level: '),
              DropdownButton<LogLevel>(
                value: _selectedLogLevel,
                items: LogLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLogLevel = value;
                    });
                  }
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  AppLogger.instance.clearLogs();
                  setState(() {});
                },
                child: const Text('Clear Logs'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingSmall),
            itemCount: AppLogger.instance.getLogCount(minLevel: _selectedLogLevel),
            itemBuilder: (context, index) {
              final logs = AppLogger.instance.getLogs(minLevel: _selectedLogLevel);
              if (index >= logs.length) return const SizedBox();
              return _buildLogEntry(logs[logs.length - 1 - index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: AppTextStyles.heading3.copyWith(color: color),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Text(
        title,
        style: AppTextStyles.heading3,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: AppTextStyles.body),
    );
  }

  Widget _buildMessageCard(Message message) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        title: Text(message.content.length > 50 ? '${message.content.substring(0, 50)}...' : message.content),
        subtitle: Text('ID: ${message.id.substring(0, 8)}...'),
        trailing: Icon(
          message.isDelivered ? Icons.check_circle : Icons.pending,
          color: message.isDelivered ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    Color logColor;
    switch (log.level) {
      case LogLevel.error:
        logColor = AppColors.danger;
        break;
      case LogLevel.warning:
        logColor = AppColors.warning;
        break;
      case LogLevel.info:
        logColor = AppColors.secondary;
        break;
      case LogLevel.debug:
        logColor = AppColors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: ListTile(
        leading: Icon(
          log.level == LogLevel.error ? Icons.error : Icons.info,
          color: logColor,
        ),
        title: Text(
          log.message,
          style: AppTextStyles.caption,
        ),
        subtitle: Text(
          '${log.timestamp.toString().substring(11, 19)} ${log.tag != null ? "[${log.tag}]" : ""}',
          style: AppTextStyles.caption.copyWith(fontSize: 10),
        ),
        isThreeLine: log.error != null,
        trailing: Text(
          log.level.name.toUpperCase(),
          style: AppTextStyles.caption.copyWith(color: logColor),
        ),
      ),
    );
  }
}

