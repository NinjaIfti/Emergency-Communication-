# Week 2 Deliverables: System Design and Architecture ✅

## Completed Tasks

### 1. ✅ Database Architecture
- **File**: `lib/database/database_helper.dart`
- **Description**: Complete SQLite database setup with table creation
- **Tables**:
  - `messages` - Store all messages with delivery status
  - `peers` - Track connected devices
  - `locations` - Store GPS coordinates linked to messages

### 2. ✅ Data Models
- **Message Model** (`lib/models/message_model.dart`)
  - Full message structure with JSON serialization
  - Support for TEXT, SOS, and ACK message types
  - Database mapping methods (toMap/fromMap)
  
- **Peer Model** (`lib/models/peer_model.dart`)
  - Device information tracking
  - Connection status management
  - Bluetooth/WiFi connection type support
  
- **Location Model** (`lib/models/location_model.dart`)
  - GPS coordinate storage
  - Accuracy tracking

### 3. ✅ Data Access Layer
- **Message DAO** (`lib/database/message_dao.dart`)
  - Insert, retrieve, update, delete messages
  - Conversation retrieval by peer
  - Undelivered message tracking
  - SOS message filtering
  
- **Peer DAO** (`lib/database/peer_dao.dart`)
  - Peer management operations
  - Connection status updates
  - Last seen timestamp tracking

### 4. ✅ Constants & Configuration
- **File**: `lib/utils/constants.dart`
- **Includes**:
  - Color scheme (Emergency red, Safe blue theme)
  - Text styles
  - Network configuration (TTL=5, ranges, limits)
  - Message packet structure
  - Routing table structure
  - App routes
  - Database table names
  - Preference keys

### 5. ✅ Architecture Documentation
- **File**: `architecture.md`
- **Contains**:
  - Overall system architecture diagram
  - Message flow sequence diagram
  - Mesh network topology diagram
  - State management flow (Provider pattern)
  - SOS alert propagation flowchart
  - Device discovery state machine
  - Complete database schema
  - Message packet JSON structure
  - Component responsibilities
  - Design patterns used
  - Security architecture

## Architecture Highlights

### System Layers
```
┌─────────────────────────┐
│   Presentation Layer    │  ← Screens & Widgets
├─────────────────────────┤
│ State Management Layer  │  ← Providers (Message, Peer, Connection)
├─────────────────────────┤
│    Service Layer        │  ← Bluetooth, WiFi, Mesh, Location, Encryption
├─────────────────────────┤
│     Data Layer          │  ← SQLite, DAOs, Shared Preferences
├─────────────────────────┤
│   Hardware Layer        │  ← Bluetooth, WiFi Direct, GPS
└─────────────────────────┘
```

### Message Packet Structure
```json
{
  "id": "uuid",
  "type": "TEXT|SOS|ACK",
  "content": "encrypted message",
  "senderId": "uuid",
  "recipientId": "uuid", 
  "timestamp": 1234567890,
  "hopCount": 0,
  "ttl": 5,
  "latitude": 23.8103,
  "longitude": 90.4125
}
```

### Design Patterns Implemented
1. **Repository Pattern** - Data abstraction
2. **Provider Pattern** - State management
3. **Singleton Pattern** - Database & services
4. **Factory Pattern** - Model creation
5. **Observer Pattern** - ChangeNotifier for UI updates

### Key Specifications
- **Max Hop Count**: 5 (TTL)
- **Max Message Size**: 512 bytes
- **Bluetooth Range**: 100 meters
- **WiFi Direct Range**: 200 meters
- **Max Peers**: 15 devices in mesh
- **Delivery Timeout**: 10 seconds
- **Encryption**: AES-256

## Files Created

```
lib/
├── database/
│   ├── database_helper.dart     ✅
│   ├── message_dao.dart          ✅
│   └── peer_dao.dart             ✅
├── models/
│   ├── message_model.dart        ✅
│   ├── peer_model.dart           ✅
│   └── location_model.dart       ✅
└── utils/
    └── constants.dart            ✅

architecture.md                   ✅
WEEK_2_DELIVERABLES.md           ✅
```

## Next Steps (Week 3)
- [ ] Design UI screens (Splash, Home, Chat, SOS, Peers, Map, Settings)
- [ ] Create color scheme implementation
- [ ] Design message bubbles
- [ ] Create SOS button with animations
- [ ] Build navigation structure

---

**Status**: ✅ Week 2 Complete  
**Date**: System Design Phase  
**Architecture**: Fully documented with diagrams and specifications


