# Emergency Offline Communication System - Architecture Documentation

## System Architecture Overview

This document describes the technical architecture of the Emergency Offline Communication System, including system design, data flow, and component interactions.

---

## 1. Overall System Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[UI Screens]
        Widgets[Reusable Widgets]
    end
    
    subgraph "State Management Layer"
        MP[Message Provider]
        PP[Peer Provider]
        CP[Connection Provider]
    end
    
    subgraph "Service Layer"
        BS[Bluetooth Service]
        WS[WiFi Direct Service]
        MS[Mesh Network Service]
        LS[Location Service]
        ES[Encryption Service]
        RS[Routing Service]
    end
    
    subgraph "Data Layer"
        DB[(SQLite Database)]
        MD[Message DAO]
        PD[Peer DAO]
        SP[Shared Preferences]
    end
    
    subgraph "Hardware Layer"
        BT[Bluetooth Hardware]
        WIFI[WiFi Direct Hardware]
        GPS[GPS Hardware]
    end
    
    UI --> MP
    UI --> PP
    UI --> CP
    Widgets --> UI
    
    MP --> MS
    MP --> ES
    PP --> BS
    PP --> WS
    CP --> BS
    CP --> WS
    
    MS --> RS
    MS --> BS
    MS --> WS
    BS --> BT
    WS --> WIFI
    LS --> GPS
    
    MP --> MD
    PP --> PD
    MD --> DB
    PD --> DB
    
    CP --> SP
```

---

## 2. Message Flow Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant UI as UI Screen
    participant MP as Message Provider
    participant ES as Encryption Service
    participant MS as Mesh Service
    participant BS as Bluetooth Service
    participant P1 as Peer Device 1
    participant P2 as Peer Device 2
    participant R as Recipient

    U->>UI: Compose Message
    UI->>MP: sendMessage()
    MP->>ES: encrypt(message)
    ES-->>MP: encrypted message
    MP->>MS: broadcastMessage()
    MS->>BS: send to connected peers
    BS->>P1: Bluetooth transmission
    BS->>P2: Bluetooth transmission
    
    P1->>P1: Check if recipient
    P1->>P1: Forward if not recipient
    P1->>R: Deliver if recipient
    
    R->>R: Decrypt message
    R->>R: Store in database
    R-->>P1: ACK
    P1-->>BS: ACK relay
    BS-->>MS: ACK received
    MS-->>MP: Update delivery status
    MP-->>UI: Update UI
    UI-->>U: Show delivered ✓
```

---

## 3. Mesh Network Topology

```mermaid
graph LR
    subgraph "Device A (Sender)"
        A[Device A<br/>Message Origin]
    end
    
    subgraph "Device B (Relay)"
        B[Device B<br/>Hop 1]
    end
    
    subgraph "Device C (Relay)"
        C[Device C<br/>Hop 2]
    end
    
    subgraph "Device D (Relay)"
        D[Device D<br/>Hop 3]
    end
    
    subgraph "Device E (Recipient)"
        E[Device E<br/>Destination]
    end
    
    A -->|BT/WiFi| B
    B -->|Forward| C
    C -->|Forward| D
    D -->|Deliver| E
    
    B -.->|Also Connected| A
    C -.->|Also Connected| B
    D -.->|Also Connected| C
    
    style A fill:#D32F2F,color:#fff
    style E fill:#4CAF50,color:#fff
    style B fill:#1976D2,color:#fff
    style C fill:#1976D2,color:#fff
    style D fill:#1976D2,color:#fff
```

### Mesh Network Rules:
- **TTL (Time to Live)**: Max 5 hops
- **Flooding Algorithm**: Broadcast to all connected peers
- **Duplicate Prevention**: Message ID tracking with LRU cache
- **Routing Table**: Dynamic updates based on peer availability

---

## 4. State Management Flow (Provider Pattern)

```mermaid
graph TD
    subgraph "UI Layer"
        S1[Chat Screen]
        S2[Peers Screen]
        S3[SOS Screen]
    end
    
    subgraph "Provider Layer"
        MP[MessageProvider<br/>ChangeNotifier]
        PP[PeerProvider<br/>ChangeNotifier]
        CP[ConnectionProvider<br/>ChangeNotifier]
    end
    
    subgraph "Widgets"
        C1[Consumer MessageProvider]
        C2[Consumer PeerProvider]
        C3[Consumer ConnectionProvider]
    end
    
    S1 --> C1
    S2 --> C2
    S3 --> C1
    S3 --> C3
    
    C1 -.Listen.-> MP
    C2 -.Listen.-> PP
    C3 -.Listen.-> CP
    
    MP -->|notifyListeners| C1
    PP -->|notifyListeners| C2
    CP -->|notifyListeners| C3
    
    style MP fill:#FFA726
    style PP fill:#FFA726
    style CP fill:#FFA726
```

---

## 5. SOS Alert Propagation

```mermaid
graph TB
    Start[User Long-Press<br/>SOS Button] --> Vibrate[Vibration Feedback]
    Vibrate --> Confirm{Confirmation<br/>Dialog}
    Confirm -->|Cancel| End[Cancel]
    Confirm -->|Confirm| GetLoc[Get GPS Location]
    
    GetLoc --> CreateSOS[Create SOS Message<br/>Type: SOS<br/>Priority: HIGH]
    CreateSOS --> Encrypt[Encrypt Content]
    Encrypt --> Queue[Add to Priority Queue]
    Queue --> Send[Send Immediately<br/>to All Peers]
    
    Send --> Repeat[Repeat 3 Times<br/>for Reliability]
    Repeat --> Store[Store in Database]
    Store --> Broadcast[Broadcast via<br/>Mesh Network]
    
    Broadcast --> P1[Peer 1<br/>Receive & Forward]
    Broadcast --> P2[Peer 2<br/>Receive & Forward]
    Broadcast --> P3[Peer 3<br/>Receive & Forward]
    
    P1 --> Spread[...Propagate to<br/>All Devices in Range]
    P2 --> Spread
    P3 --> Spread
    
    style Start fill:#D32F2F,color:#fff
    style CreateSOS fill:#FFA726
    style Broadcast fill:#4CAF50,color:#fff
```

---

## 6. Device Discovery Process

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Scanning: Start Scan
    
    Scanning --> DeviceFound: Device Discovered
    DeviceFound --> Connecting: Initiate Connection
    
    Connecting --> Connected: Success
    Connecting --> Failed: Connection Failed
    
    Connected --> UpdateRouting: Update Routing Table
    UpdateRouting --> Active: Add to Peer List
    
    Active --> Disconnected: Connection Lost
    Disconnected --> Scanning: Resume Scan
    
    Failed --> Scanning: Retry
    
    Active --> [*]: App Closed
    
    note right of Scanning
        Continuous background scan
        Auto-connect to discovered peers
    end note
    
    note right of UpdateRouting
        - Add peer to routing table
        - Share routing info
        - Update hop counts
    end note
```

---

## 7. Database Schema

### Messages Table
```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,              -- UUID
  content TEXT NOT NULL,            -- Encrypted message content
  sender_id TEXT NOT NULL,          -- Sender UUID
  recipient_id TEXT NOT NULL,       -- Recipient UUID
  timestamp INTEGER NOT NULL,       -- Unix timestamp
  is_delivered INTEGER DEFAULT 0,  -- Boolean (0/1)
  hop_count INTEGER DEFAULT 0,      -- Number of hops
  message_type TEXT NOT NULL        -- TEXT|SOS|ACK
);
```

### Peers Table
```sql
CREATE TABLE peers (
  peer_id TEXT PRIMARY KEY,         -- Peer UUID
  device_name TEXT NOT NULL,        -- Device name
  last_seen INTEGER NOT NULL,       -- Last seen timestamp
  is_connected INTEGER DEFAULT 0,   -- Boolean (0/1)
  connection_type TEXT              -- BLUETOOTH|WIFI
);
```

### Locations Table
```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id TEXT NOT NULL,         -- Foreign key to messages
  latitude REAL NOT NULL,           -- GPS latitude
  longitude REAL NOT NULL,          -- GPS longitude
  accuracy REAL,                    -- GPS accuracy in meters
  FOREIGN KEY (message_id) REFERENCES messages(id)
);
```

---

## 8. Message Packet Structure

### Standard Packet Format (JSON)
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "type": "TEXT|SOS|ACK",
  "content": "Encrypted message content",
  "senderId": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
  "recipientId": "f1e2d3c4-b5a6-9870-4321-0fedcba09876",
  "timestamp": 1699564800000,
  "hopCount": 0,
  "ttl": 5,
  "latitude": 23.8103,
  "longitude": 90.4125
}
```

### Field Descriptions:
- **id**: Unique message identifier (UUID v4)
- **type**: Message type (TEXT, SOS, or ACK)
- **content**: Encrypted message payload
- **senderId**: Originating device ID
- **recipientId**: Destination device ID
- **timestamp**: Creation time (Unix milliseconds)
- **hopCount**: Number of hops from origin
- **ttl**: Time to Live (decrements each hop, max 5)
- **latitude/longitude**: GPS coordinates (optional)

---

## 9. Component Responsibilities

### Presentation Layer
- **Screens**: Handle user interaction and display
- **Widgets**: Reusable UI components
- **Navigation**: Route management

### State Management
- **Providers**: Manage app state and notify listeners
- **ChangeNotifier**: Reactive state updates

### Service Layer
- **Bluetooth Service**: Device discovery, connection management
- **WiFi Direct Service**: WiFi P2P communication
- **Mesh Network Service**: Message routing, forwarding logic
- **Location Service**: GPS tracking
- **Encryption Service**: AES-256 encryption/decryption
- **Routing Service**: Route calculation, duplicate prevention

### Data Layer
- **Database Helper**: SQLite initialization
- **DAOs**: Data access objects for CRUD operations
- **Models**: Data classes with serialization

---

## 10. Key Design Patterns

1. **Repository Pattern**: Abstraction over data sources
2. **Provider Pattern**: State management and dependency injection
3. **Singleton Pattern**: Database instance, service instances
4. **Factory Pattern**: Model creation from JSON/Map
5. **Observer Pattern**: State change notifications via ChangeNotifier

---

## 11. Security Architecture

```mermaid
graph LR
    Plain[Plain Message] --> Key[AES-256 Key]
    Key --> Encrypt[Encrypt]
    Encrypt --> Send[Transmit]
    
    Send --> Receive[Receive]
    Receive --> Decrypt[Decrypt]
    Decrypt --> Key2[Same AES Key]
    Key2 --> Display[Display Message]
    
    style Key fill:#FFA726
    style Key2 fill:#FFA726
```

### Security Features:
- **Encryption**: AES-256 for message content
- **Key Storage**: Secure storage using flutter_secure_storage
- **Key Exchange**: Pre-shared key (simple implementation)
- **Data Integrity**: Message checksum validation

---

## Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.10+ |
| Language | Dart |
| Database | SQLite (sqflite) |
| Bluetooth | flutter_blue_plus |
| WiFi Direct | wifi_iot (Android only) |
| Location | geolocator |
| Encryption | encrypt (AES) |
| State Management | Provider |
| Storage | shared_preferences |

---

**Document Version**: 1.0  
**Last Updated**: Week 2 - System Design Phase

