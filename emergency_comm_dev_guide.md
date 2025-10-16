# Emergency Offline Communication System - Development Guide for Cursor AI

## Project Overview
Flutter application for emergency communication using Bluetooth and Wi-Fi Direct mesh networking. No cellular/internet required. Target: disaster-affected areas in Bangladesh and similar regions.

## Core Technology Stack
- **Framework**: Flutter (SDK 3.10+)
- **Language**: Dart
- **Database**: SQLite (sqflite package)
- **Bluetooth**: flutter_blue_plus package
- **Wi-Fi Direct**: wifi_iot package (Android only)
- **Location**: geolocator package
- **Encryption**: encrypt package
- **State Management**: Provider or Riverpod
- **Local Storage**: shared_preferences for settings

## Required Packages (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  flutter_blue_plus: ^1.31.0
  wifi_iot: ^0.3.19
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  encrypt: ^5.0.3
  provider: ^6.1.1
  uuid: ^4.1.0
  shared_preferences: ^2.2.2
```

## Project Structure
```
lib/
├── main.dart
├── models/
│   ├── message_model.dart
│   ├── peer_model.dart
│   └── location_model.dart
├── database/
│   ├── database_helper.dart
│   ├── message_dao.dart
│   └── peer_dao.dart
├── services/
│   ├── bluetooth_service.dart
│   ├── wifi_direct_service.dart
│   ├── mesh_network_service.dart
│   ├── location_service.dart
│   ├── encryption_service.dart
│   └── message_routing_service.dart
├── providers/
│   ├── message_provider.dart
│   ├── peer_provider.dart
│   └── connection_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── sos_screen.dart
│   ├── peers_screen.dart
│   ├── map_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── message_bubble.dart
│   ├── peer_tile.dart
│   ├── sos_button.dart
│   └── connection_indicator.dart
└── utils/
    ├── constants.dart
    ├── permissions_helper.dart
    └── battery_optimizer.dart
```

---

## 12-Week Development Schedule

### WEEK 1: Research and Requirement Analysis
**Deliverables**: Requirements document, comparison analysis

**Tasks**:
1. Research existing apps (Bridgefy, FireChat, Briar)
2. Document technical requirements:
   - Minimum Flutter SDK version
   - Android permissions needed
   - iOS limitations (Wi-Fi Direct not available)
   - Battery constraints
   - Maximum message size: 512 bytes
   - Network range: 100m Bluetooth, 200m Wi-Fi Direct
3. Hardware requirements:
   - Bluetooth 4.0+ support
   - Wi-Fi Direct capable Android devices
   - GPS accuracy requirements
4. Define project scope:
   - Support 10-15 devices in mesh
   - Message delivery within 10 seconds
   - Text messages only (no media)
5. List limitations:
   - Android-only for full functionality
   - iOS limited to Bluetooth only
   - Power consumption estimates

**Cursor Instructions**:
```
Create requirements.md with:
- List all Flutter packages needed with versions
- Document Android permissions in AndroidManifest.xml format
- Create comparison table: Bridgefy vs FireChat vs Our App
- List all limitations and constraints
- Define message size limits and network specifications
```

---

### WEEK 2: System Design and Architecture
**Deliverables**: Architecture diagrams, database schema, flowcharts

**Tasks**:
1. Design system architecture:
   - Provider pattern for state management
   - Service layer for business logic
   - Repository pattern for database access
2. Create flowcharts:
   - Message sending flow
   - Mesh network formation
   - SOS alert propagation
   - Device discovery process
3. Design mesh network protocol:
   - Message packet structure (JSON format)
   - Routing table format
   - Node identification using UUID
   - TTL (Time to Live): 5 hops maximum
4. SQLite database schema:
   ```sql
   CREATE TABLE messages (
     id TEXT PRIMARY KEY,
     content TEXT NOT NULL,
     sender_id TEXT NOT NULL,
     recipient_id TEXT NOT NULL,
     timestamp INTEGER NOT NULL,
     is_delivered INTEGER DEFAULT 0,
     hop_count INTEGER DEFAULT 0,
     message_type TEXT NOT NULL
   );

   CREATE TABLE peers (
     peer_id TEXT PRIMARY KEY,
     device_name TEXT NOT NULL,
     last_seen INTEGER NOT NULL,
     is_connected INTEGER DEFAULT 0,
     connection_type TEXT
   );

   CREATE TABLE locations (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     message_id TEXT NOT NULL,
     latitude REAL NOT NULL,
     longitude REAL NOT NULL,
     accuracy REAL,
     FOREIGN KEY (message_id) REFERENCES messages(id)
   );
   ```
5. Define message packet format:
   ```json
   {
     "id": "uuid",
     "type": "TEXT|SOS|ACK",
     "content": "message text",
     "senderId": "uuid",
     "recipientId": "uuid",
     "timestamp": 1234567890,
     "hopCount": 0,
     "ttl": 5,
     "latitude": 23.8103,
     "longitude": 90.4125
   }
   ```

**Cursor Instructions**:
```
Generate:
1. database_helper.dart with complete SQLite setup
2. message_model.dart with fromJson and toJson methods
3. peer_model.dart with connection status tracking
4. Create architecture.md with Mermaid diagrams for:
   - Overall system architecture
   - Message flow diagram
   - Mesh network topology
   - State management flow
5. Document message packet structure in constants.dart
```

---

### WEEK 3: UI/UX Design
**Deliverables**: Complete UI screens, design system

**Tasks**:
1. Design screens in Flutter:
   - Splash screen with app logo
   - Home screen with connected peers count
   - Chat screen (WhatsApp-like interface)
   - SOS screen with large red button
   - Map screen for location display
   - Peers list screen
   - Settings screen
2. Color scheme:
   ```dart
   Primary: Color(0xFFD32F2F)  // Emergency red
   Secondary: Color(0xFF1976D2)  // Safe blue
   Background: Color(0xFFFAFAFA)
   Dark: Color(0xFF212121)
   ```
3. Design SOS button:
   - Minimum size: 200x200
   - Center of screen
   - Red with white icon
   - Haptic feedback on press
   - Confirmation dialog
4. Create navigation structure:
   - Bottom navigation bar
   - Named routes
5. Design message bubbles:
   - Sent: Right-aligned, blue
   - Received: Left-aligned, grey
   - Delivery status icons

**Cursor Instructions**:
```
Create:
1. splash_screen.dart with fade-in animation
2. home_screen.dart with connection status indicator
3. chat_screen.dart with ListView.builder for messages
4. sos_screen.dart with GestureDetector for long-press
5. peers_screen.dart with ListView of connected devices
6. map_screen.dart with basic coordinate display
7. settings_screen.dart with ListView of options
8. constants.dart with all colors, text styles, sizes
9. message_bubble.dart widget with sent/received styling
10. sos_button.dart widget with animation
```

---

### WEEK 4: Environment Setup and Initial Coding
**Deliverables**: Working project scaffold, permission handling

**Tasks**:
1. Create Flutter project:
   ```bash
   flutter create emergency_offline_comm
   ```
2. Configure pubspec.yaml with all dependencies
3. Android configuration (android/app/src/main/AndroidManifest.xml):
   ```xml
   <uses-permission android:name="android.permission.BLUETOOTH"/>
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   <uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
   <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES"/>
   ```
4. Set up SQLite database:
   - Create database helper class
   - Implement table creation
   - Test database operations
5. Implement permission handler:
   - Request Bluetooth permissions
   - Request location permissions
   - Handle permission denials
6. Initialize services:
   - Bluetooth service skeleton
   - Location service skeleton
   - Database service

**Cursor Instructions**:
```
Generate:
1. Complete pubspec.yaml with all packages
2. database_helper.dart with:
   - initDatabase() method
   - createTables() method
   - getDatabasePath() using path_provider
3. permissions_helper.dart with:
   - requestBluetoothPermissions()
   - requestLocationPermissions()
   - checkAllPermissions()
4. main.dart with:
   - MultiProvider setup
   - Theme configuration
   - Named routes
5. bluetooth_service.dart skeleton with:
   - FlutterBluePlus initialization
   - checkBluetoothSupport() method
6. location_service.dart skeleton with:
   - Geolocator initialization
   - getCurrentLocation() method
```

---

### WEEK 5: Offline Messaging Module Development
**Deliverables**: Working P2P messaging between 2 devices

**Tasks**:
1. Implement Bluetooth connection:
   - Scan for nearby devices
   - Connect to peer device
   - Establish RFCOMM socket
2. Implement message sending:
   ```dart
   Future<void> sendMessage(Message message) async {
     final jsonMessage = message.toJson();
     final bytes = utf8.encode(jsonEncode(jsonMessage));
     await characteristic.write(bytes);
   }
   ```
3. Implement message receiving:
   - Listen to Bluetooth characteristic
   - Parse incoming JSON
   - Store in SQLite database
   - Update UI via Provider
4. Create message queue:
   - Queue unsent messages
   - Retry failed messages
   - Persist queue to database
5. Test with 2 physical devices:
   - Send text message
   - Verify delivery
   - Check database storage

**Cursor Instructions**:
```
Generate:
1. bluetooth_service.dart with:
   - startScan() method
   - connectToPeer(BluetoothDevice device) method
   - sendMessage(Message message) method
   - listenForMessages() method using StreamSubscription
2. message_provider.dart with:
   - sendMessage() method
   - receiveMessage() method
   - List<Message> messages state
   - notifyListeners() calls
3. message_dao.dart with:
   - insertMessage(Message message)
   - getAllMessages()
   - updateMessageStatus(String id, bool delivered)
4. chat_screen.dart with:
   - Consumer<MessageProvider> for reactive UI
   - TextField for message input
   - ListView.builder for message list
   - Send button functionality
5. Add proper error handling with try-catch blocks
```

---

### WEEK 6: Mesh Networking Implementation
**Deliverables**: Multi-hop messaging across 3-4 devices

**Tasks**:
1. Implement routing table:
   ```dart
   class RoutingTable {
     Map<String, PeerRoute> routes = {};
     void addRoute(String peerId, String nextHop, int hopCount);
     String? getNextHop(String destinationId);
     void updateRoutes(List<Peer> connectedPeers);
   }
   ```
2. Message forwarding logic:
   - Check if message is for this device
   - If not, forward to next hop
   - Increment hop count
   - Check TTL before forwarding
3. Prevent message loops:
   - Maintain seen message cache (LRU)
   - Store message IDs with timestamps
   - Discard duplicates
4. Implement flooding algorithm:
   - Broadcast to all connected peers
   - Use TTL to limit propagation
   - Track message IDs
5. Device discovery:
   - Continuous background scan
   - Auto-connect to discovered peers
   - Handle connection drops
6. Test with 4 devices in chain: A -> B -> C -> D

**Cursor Instructions**:
```
Generate:
1. mesh_network_service.dart with:
   - RoutingTable class
   - forwardMessage(Message message) method
   - broadcastMessage(Message message) method
   - updateRoutingTable() method
2. message_routing_service.dart with:
   - Map<String, DateTime> seenMessages cache
   - shouldForwardMessage(Message message) method
   - getNextHopForMessage(Message message) method
   - cleanupSeenMessages() method (remove old entries)
3. peer_provider.dart with:
   - List<Peer> connectedPeers state
   - addPeer(Peer peer) method
   - removePeer(String peerId) method
   - updatePeerStatus(String peerId, bool connected) method
4. Update bluetooth_service.dart:
   - Add multi-peer connection support
   - Implement connection pool
   - Handle simultaneous connections
5. Add logging for message paths using print() or logger package
```

---

### WEEK 7: SOS and GPS Integration
**Deliverables**: Working SOS alert with location sharing

**Tasks**:
1. Implement location service:
   ```dart
   Future<Position> getCurrentLocation() async {
     return await Geolocator.getCurrentPosition(
       desiredAccuracy: LocationAccuracy.high,
     );
   }
   ```
2. Create SOS message model:
   ```dart
   class SOSMessage extends Message {
     final double latitude;
     final double longitude;
     final double accuracy;
     final String userName;
   }
   ```
3. Implement SOS button:
   - Long-press detection (2 seconds)
   - Vibration feedback using vibration package
   - Confirmation dialog
   - Visual feedback animation
4. SOS broadcast:
   - Highest priority in queue
   - Send to all connected peers immediately
   - Repeat 3 times for reliability
5. Create map screen:
   - Display SOS locations
   - Show coordinates as text
   - Calculate distance from current location
6. Test GPS accuracy:
   - Indoor vs outdoor
   - Different weather conditions

**Cursor Instructions**:
```
Generate:
1. location_service.dart with:
   - getCurrentLocation() method
   - checkLocationPermission() method
   - startLocationUpdates() stream
   - getLastKnownLocation() fallback
2. sos_screen.dart with:
   - GestureDetector with onLongPress
   - CircularProgressIndicator for press duration
   - showDialog for confirmation
   - Vibration.vibrate() on send
3. Update message_model.dart:
   - Add latitude and longitude fields
   - Add messageType enum (TEXT, SOS, ACK)
   - Update toJson/fromJson
4. Update mesh_network_service.dart:
   - Add priority queue for messages
   - Implement sendSOSMessage() with repeat logic
5. map_screen.dart with:
   - ListView of SOS locations
   - Display lat/long as text
   - Show timestamp
   - Calculate distance using Geolocator.distanceBetween()
6. Add vibration package to pubspec.yaml
```

---

### WEEK 8: Message Encryption and Data Handling
**Deliverables**: Encrypted message transmission, reliable delivery

**Tasks**:
1. Implement encryption:
   ```dart
   final key = Key.fromUtf8('32-character-key-here-12345678');
   final iv = IV.fromLength(16);
   final encrypter = Encrypter(AES(key));
   final encrypted = encrypter.encrypt(plainText, iv: iv);
   ```
2. Encrypt message content:
   - Encrypt before sending
   - Decrypt after receiving
   - Use AES-256 encryption
3. Key management:
   - Generate shared key on first connection
   - Store key securely using flutter_secure_storage
   - Key exchange using simple pre-shared key
4. Message queue with priority:
   ```dart
   class MessageQueue {
     List<Message> sosMessages = [];
     List<Message> regularMessages = [];
     Message? getNextMessage();
   }
   ```
5. Delivery confirmation:
   - Send ACK message on receipt
   - Update message status in database
   - Show delivery indicators in UI
6. Data integrity:
   - Add checksum to messages
   - Validate on receive
   - Discard corrupted messages

**Cursor Instructions**:
```
Generate:
1. encryption_service.dart with:
   - encryptMessage(String content) method
   - decryptMessage(String encrypted) method
   - generateKey() method
   - storeKey() using flutter_secure_storage
2. Update bluetooth_service.dart:
   - Encrypt before sending
   - Decrypt after receiving
3. Create message_queue.dart with:
   - PriorityQueue class
   - enqueueMessage(Message message) method
   - dequeueMessage() method
   - Priority: SOS > Regular
4. Update message_provider.dart:
   - Implement ACK message handling
   - Update message delivery status
   - Notify UI on status change
5. Add message status enum:
   - PENDING, SENT, DELIVERED, FAILED
6. Update message_bubble.dart:
   - Show checkmark icons for status
   - Grey checkmark: sent
   - Blue double checkmark: delivered
7. Add flutter_secure_storage to pubspec.yaml
```

---

### WEEK 9: UI Integration and Optimization
**Deliverables**: Complete working app with polished UI

**Tasks**:
1. Connect all services to UI:
   - Use Provider for state management
   - Update UI reactively
   - Handle loading states
2. Enhance chat screen:
   - Auto-scroll to latest message
   - Show typing indicator
   - Message timestamps
   - Delivery status icons
   - Pull to refresh
3. Enhance peers screen:
   - Show connection status (green/grey dot)
   - Show last seen time
   - Connection type badge (BT/WiFi)
   - Tap to view details
4. Battery optimization:
   ```dart
   Timer.periodic(Duration(seconds: 30), (timer) {
     if (connectedPeers.isEmpty) {
       reduceScanFrequency();
     }
   });
   ```
5. Add loading indicators:
   - Sending message
   - Connecting to peer
   - Scanning for devices
6. Implement settings screen:
   - Username input
   - Auto-connect toggle
   - Clear message history
   - About section with version

**Cursor Instructions**:
```
Generate:
1. Update home_screen.dart with:
   - Consumer<ConnectionProvider> for connection status
   - Consumer<PeerProvider> for peer count
   - FloatingActionButton to SOS screen
   - Status indicator widget
2. Update chat_screen.dart with:
   - ScrollController for auto-scroll
   - RefreshIndicator for pull to refresh
   - DateFormat for timestamps
   - Delivery status icons
3. Update peers_screen.dart with:
   - peer_tile.dart widget
   - Connection indicator (CircleAvatar with color)
   - Last seen with timeago package
   - Connection type badge
4. battery_optimizer.dart with:
   - reduceScanFrequency() method
   - closeIdleConnections() method
   - Timer-based optimization
5. settings_screen.dart with:
   - TextFormField for username
   - SwitchListTile for auto-connect
   - ListTile for clear history
   - AboutListTile
6. Add loading states in providers using bool isLoading
7. Add timeago package to pubspec.yaml
```

---

### WEEK 10: Testing and Debugging
**Deliverables**: Bug-free, stable application

**Tasks**:
1. Unit testing:
   ```dart
   test('Message encryption/decryption', () {
     final encrypted = encryptionService.encrypt('Hello');
     final decrypted = encryptionService.decrypt(encrypted);
     expect(decrypted, 'Hello');
   });
   ```
2. Widget testing:
   - Test message bubble rendering
   - Test SOS button functionality
   - Test peer list display
3. Integration testing:
   - Full message flow test
   - SOS propagation test
   - Multi-device connection test
4. Real-world testing:
   - Test in areas with no network
   - Test with 5-10 devices
   - Test battery drain over 2 hours
   - Test range: walk 50m, 100m, 150m apart
5. Stress testing:
   - Send 100 messages rapidly
   - Connect 15 peers simultaneously
   - Test with 1000 characters messages
6. Fix bugs:
   - Connection drops
   - Message loss
   - UI freezes
   - Memory leaks
   - Battery drain
7. Test on different devices:
   - Samsung, Xiaomi, OnePlus
   - Different Android versions (9, 10, 11, 12, 13)
   - Low-end devices with 2GB RAM

**Cursor Instructions**:
```
Generate:
1. test/ folder with:
   - encryption_service_test.dart
   - message_model_test.dart
   - routing_table_test.dart
2. integration_test/ folder with:
   - app_test.dart for full flow testing
3. Add logging throughout app:
   - logger package
   - Log all message sends/receives
   - Log connection events
   - Log errors with stack traces
4. Create debug_screen.dart with:
   - Connection statistics
   - Message count
   - Error log viewer
5. Implement error handling:
   - Wrap all async operations in try-catch
   - Show SnackBar on errors
   - Log errors for debugging
6. Memory leak detection:
   - Dispose controllers properly
   - Cancel StreamSubscriptions
   - Close database connections
7. Add logger package to pubspec.yaml
```

---

### WEEK 11: Documentation and Report Preparation
**Deliverables**: Complete documentation package

**Tasks**:
1. User manual (user_manual.md):
   - Installation steps from APK
   - First-time setup with screenshots
   - How to send messages
   - How to use SOS feature
   - Troubleshooting common issues
   - FAQ section
2. Technical documentation (technical_docs.md):
   - Architecture overview with diagrams
   - Database schema with ER diagram
   - Message protocol specification
   - API documentation for services
   - Code structure explanation
3. Developer guide (developer_guide.md):
   - How to build: flutter build apk
   - Dependencies list with versions
   - How to add new features
   - Code conventions used
4. Test results (test_results.md):
   - Performance metrics table
   - Range test results graph
   - Battery consumption data
   - Success