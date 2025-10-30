import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/peer_tile.dart';
import '../models/peer_model.dart';

class PeersScreen extends StatefulWidget {
  const PeersScreen({super.key});

  @override
  State<PeersScreen> createState() => _PeersScreenState();
}

class _PeersScreenState extends State<PeersScreen> {
  bool _isScanning = false;
  final List<Peer> _peers = [];

  void _startScan() {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          // Add mock peers for demonstration
          if (_peers.isEmpty) {
            _peers.addAll([
              Peer(
                peerId: 'peer1',
                deviceName: 'John\'s Phone',
                lastSeen: DateTime.now().millisecondsSinceEpoch,
                isConnected: true,
                connectionType: ConnectionType.BLUETOOTH,
              ),
              Peer(
                peerId: 'peer2',
                deviceName: 'Sarah\'s Device',
                lastSeen:
                    DateTime.now().millisecondsSinceEpoch - (2 * 60 * 1000),
                isConnected: false,
                connectionType: ConnectionType.WIFI,
              ),
            ]);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            color: AppColors.lightGrey,
            child: Row(
              children: [
                Icon(
                  _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                Text(
                  _isScanning
                      ? 'Scanning for devices...'
                      : '${_peers.where((p) => p.isConnected).length} connected, ${_peers.length} total',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),

          // Peer List
          Expanded(
            child: _peers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_outlined,
                          size: 80,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          _isScanning
                              ? 'Searching for devices...'
                              : 'No devices found',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        if (!_isScanning) ...[
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'Tap refresh to scan',
                            style: AppTextStyles.caption,
                          ),
                        ],
                        if (_isScanning) ...[
                          const SizedBox(height: AppSizes.paddingMedium),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: _peers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSizes.paddingSmall),
                    itemBuilder: (context, index) {
                      final peer = _peers[index];
                      return PeerTile(
                        peer: peer,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: {
                              'peerName': peer.deviceName,
                              'peerId': peer.peerId,
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: AppColors.success,
        child: Icon(_isScanning ? Icons.hourglass_empty : Icons.search),
      ),
    );
  }
}


