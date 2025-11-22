import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../widgets/peer_tile.dart';
import '../providers/peer_provider.dart';

class PeersScreen extends StatefulWidget {
  const PeersScreen({super.key});

  @override
  State<PeersScreen> createState() => _PeersScreenState();
}

class _PeersScreenState extends State<PeersScreen> {
  @override
  void initState() {
    super.initState();
    // Load existing peers when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PeerProvider>(context, listen: false).loadPeers();
    });
  }

  void _startScan() {
    // Start real Bluetooth scanning using PeerProvider
    Provider.of<PeerProvider>(context, listen: false).startScanning();
  }

  void _stopScan() {
    // Stop Bluetooth scanning
    Provider.of<PeerProvider>(context, listen: false).stopScanning();
  }

  void _connectToPeer(String peerId) async {
    final peerProvider = Provider.of<PeerProvider>(context, listen: false);
    
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    bool connected = await peerProvider.connectToPeer(peerId);
    
    if (mounted) {
      if (connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error from provider if available, otherwise generic message
        final errorMessage = peerProvider.error ?? 
            'Connection failed. Only devices running this app can connect.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PeerProvider>(
      builder: (context, peerProvider, child) {
        final peers = peerProvider.peers;
        final connectedCount = peerProvider.connectedPeerCount;
        final isScanning = peerProvider.isScanning;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Nearby Devices'),
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.white,
            actions: [
              IconButton(
                icon: Icon(isScanning ? Icons.stop : Icons.refresh),
                onPressed: isScanning ? _stopScan : _startScan,
                tooltip: isScanning ? 'Stop Scanning' : 'Start Scanning',
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
                      isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: Text(
                        isScanning
                            ? 'Scanning for devices...'
                            : '$connectedCount connected, ${peers.length} total',
                        style: AppTextStyles.body,
                      ),
                    ),
                    if (isScanning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),

              // Error Message
              if (peerProvider.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingSmall),
                  color: AppColors.danger.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(
                        child: Text(
                          peerProvider.error!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => peerProvider.clearError(),
                      ),
                    ],
                  ),
                ),

              // Peer List
              Expanded(
                child: peerProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : peers.isEmpty
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
                                  isScanning
                                      ? 'Searching for devices...'
                                      : 'No devices found',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                                if (!isScanning) ...[
                                  const SizedBox(height: AppSizes.paddingSmall),
                                  Text(
                                    'Tap the scan button to find nearby devices',
                                    style: AppTextStyles.caption,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                            itemCount: peers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSizes.paddingSmall),
                            itemBuilder: (context, index) {
                              final peer = peers[index];
                              return PeerTile(
                                peer: peer,
                                onTap: () {
                                  // Connect if not connected, otherwise navigate to chat
                                  if (peer.isConnected) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.chat,
                                      arguments: {
                                        'peerName': peer.deviceName,
                                        'peerId': peer.peerId,
                                      },
                                    );
                                  } else {
                                    _connectToPeer(peer.peerId);
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isScanning ? _stopScan : _startScan,
            backgroundColor: AppColors.success,
            icon: Icon(isScanning ? Icons.stop : Icons.search),
            label: Text(isScanning ? 'Stop' : 'Scan'),
          ),
        );
      },
    );
  }
}


