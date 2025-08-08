# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.0.1] - 2025-08-08

### Added
- Add GitHub Actions workflow for automated testing and publishing
- Add OIDC authentication for secure package publishing
- Add documentation for automated publishing process
- Add documentation for OIDC authentication setup

## [1.0.0] - 2025-01-06

### Added
- Initial release of WuKong Easy SDK for Flutter
- WebSocket-based real-time communication with WuKongIM server
- JSON-RPC protocol implementation
- Singleton SDK pattern with `WuKongEasySDK.getInstance()`
- Configuration-driven initialization with `WuKongConfig`
- Event-driven architecture with type-safe event listeners
- Support for multiple event listeners per event type
- Automatic reconnection with exponential backoff
- Ping/pong heartbeat mechanism
- Message sending and receiving functionality
- Comprehensive error handling with custom exception types
- Cross-platform support (iOS, Android, Web, Desktop)

### Core Features
- **Connection Management**: Connect, disconnect, and automatic reconnection
- **Message Handling**: Send and receive messages with acknowledgments
- **Event System**: Connect, disconnect, message, and error events
- **Type Safety**: Full Dart type safety with null safety support
- **Error Handling**: Specific exception types for different error scenarios

### API Components
- `WuKongEasySDK` - Main SDK class with singleton pattern
- `WuKongConfig` - Configuration class for server connection
- `WuKongEvent` - Event types enum (connect, disconnect, message, error)
- `WuKongChannelType` - Channel types enum (person, group, etc.)
- `WuKongDeviceFlag` - Device flag enum (app, web)
- `ConnectResult` - Connection result data class
- `DisconnectInfo` - Disconnection information data class
- `Message` - Received message data class
- `MessagePayload` - Message payload data class
- `SendResult` - Message send result data class
- `WuKongError` - Error information data class

### Exception Types
- `WuKongNotConnectedException` - Thrown when not connected
- `WuKongInvalidChannelException` - Thrown for invalid channels
- `WuKongMessageTooLargeException` - Thrown for oversized messages
- `WuKongAuthenticationException` - Thrown for auth failures
- `WuKongConnectionTimeoutException` - Thrown for timeouts
- `WuKongNetworkException` - Thrown for network errors
- `WuKongConfigurationException` - Thrown for config errors
- `WuKongProtocolException` - Thrown for protocol errors

### Documentation
- Comprehensive README with quick start guide
- API reference documentation
- Best practices for event listener management
- Example application demonstrating all features
- Unit tests covering core functionality

### Dependencies
- `web_socket_channel: ^3.0.0` - Cross-platform WebSocket support
- `uuid: ^4.0.0` - UUID generation for message IDs

### Requirements
- Flutter 3.0.0 or higher
- Dart 2.17.0 or higher
