import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import '../models/message_model.dart';
import '../database/message_dao.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MessageDao _messageDao = MessageDao();
  List<Message> _sosMessages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSOSMessages();
  }

  Future<void> _loadSOSMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sosMessages = await _messageDao.getSOSMessages();
      
      // Filter to only show messages with location coordinates
      final messagesWithLocation = sosMessages.where((msg) => 
        msg.latitude != null && msg.longitude != null
      ).toList();
      
      setState(() {
        _sosMessages = messagesWithLocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load SOS messages: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Locations'),
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            color: AppColors.warning.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: Text(
                    _isLoading 
                        ? 'Loading SOS locations...'
                        : 'Showing ${_sosMessages.length} emergency locations',
                    style: AppTextStyles.body,
                  ),
                ),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSOSMessages,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
          ),

          // Map View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _sosMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map,
                              size: 100,
                              color: AppColors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            Text(
                              'Interactive Map View',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingSmall),
                            Text(
                              'No SOS locations to display',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      )
                    : _buildMapView(),
          ),

          // Location List or Empty State
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.paddingLarge),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingLarge),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.danger,
                              ),
                              const SizedBox(height: AppSizes.paddingMedium),
                              Text(
                                _error!,
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSizes.paddingMedium),
                              ElevatedButton.icon(
                                onPressed: _loadSOSMessages,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _sosMessages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.paddingLarge),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 48,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(height: AppSizes.paddingMedium),
                                  Text(
                                    'No SOS locations found',
                                    style: AppTextStyles.heading3,
                                  ),
                                  const SizedBox(height: AppSizes.paddingSmall),
                                  Text(
                                    'SOS alerts with location will appear here',
                                    style: AppTextStyles.caption,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                            itemCount: _sosMessages.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final message = _sosMessages[index];
                final timeAgo = _getTimeAgo(message.timestamp);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.emergency,
                      color: AppColors.white,
                    ),
                  ),
                  title: Text(
                    message.content,
                    style: AppTextStyles.body,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${message.latitude?.toStringAsFixed(4)}°N, ${message.longitude?.toStringAsFixed(4)}°E',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  onTap: () {
                    _showLocationDetails(context, message);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build the interactive map view
  Widget _buildMapView() {
    // Calculate center point from SOS messages
    LatLng? centerPoint;
    if (_sosMessages.isNotEmpty && 
        _sosMessages.first.latitude != null && 
        _sosMessages.first.longitude != null) {
      centerPoint = LatLng(
        _sosMessages.first.latitude!,
        _sosMessages.first.longitude!,
      );
    } else {
      // Default center (Bangladesh coordinates)
      centerPoint = const LatLng(23.8103, 90.4125);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: _sosMessages.length == 1 ? 15.0 : 12.0,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: (tapPosition, point) {
          // Find SOS message at tapped location
          for (var message in _sosMessages) {
            if (message.latitude != null && message.longitude != null) {
              final distance = _calculateDistance(
                point.latitude,
                point.longitude,
                message.latitude!,
                message.longitude!,
              );
              // If tapped within 500m of a marker, show details
              if (distance < 500) {
                _showLocationDetails(context, message);
                break;
              }
            }
          }
        },
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.emergenccy_communication',
          maxZoom: 19,
          minZoom: 5,
        ),
        // SOS location markers
        MarkerLayer(
          markers: _sosMessages
              .where((msg) => msg.latitude != null && msg.longitude != null)
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final message = entry.value;
            final isMostRecent = index == 0;
            
            return Marker(
              point: LatLng(message.latitude!, message.longitude!),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showLocationDetails(context, message),
                child: Container(
                  decoration: BoxDecoration(
                    color: isMostRecent ? AppColors.primary : AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Calculate distance between two points (in meters)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _showLocationDetails(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: AppSizes.paddingMedium),
                Expanded(
                  child: Text(
                    'SOS Location Details',
                    style: AppTextStyles.heading2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            _DetailRow(
              icon: Icons.message,
              label: 'Message',
              value: message.content,
            ),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Coordinates',
              value:
                  '${message.latitude?.toStringAsFixed(6)}°N, ${message.longitude?.toStringAsFixed(6)}°E',
            ),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Time',
              value: _getTimeAgo(message.timestamp),
            ),
            _DetailRow(
              icon: Icons.person,
              label: 'Sender',
              value: message.senderId,
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationMarker extends StatelessWidget {
  final bool isActive;

  const _LocationMarker({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.emergency,
        color: AppColors.white,
        size: 20,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSizes.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                Text(
                  value,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for map grid background
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


