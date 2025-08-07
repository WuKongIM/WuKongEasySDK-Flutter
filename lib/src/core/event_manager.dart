import 'dart:developer' as developer;

import '../enums/wukong_event.dart';
import '../utils/event_listener.dart';

/// Event manager for handling event listeners and dispatching events
/// 
/// Manages event listener registration, removal, and event dispatching with type safety.
class EventManager {
  /// Map of event types to their listeners
  final Map<WuKongEvent, List<Function>> _listeners = {};
  
  /// Creates a new event manager
  EventManager() {
    // Initialize listener lists for all event types
    for (final event in WuKongEvent.values) {
      _listeners[event] = [];
    }
  }
  
  /// Adds an event listener for the specified event type
  /// 
  /// [event] The event type to listen for
  /// [listener] The listener function to call when the event occurs
  void addEventListener<T>(WuKongEvent event, WuKongEventListener<T> listener) {
    final listeners = _listeners[event];
    if (listeners != null) {
      listeners.add(listener);
      developer.log('Added event listener for $event. Total listeners: ${listeners.length}');
    } else {
      developer.log('Warning: Attempted to add listener for unknown event: $event');
    }
  }
  
  /// Removes a specific event listener for the specified event type
  /// 
  /// [event] The event type to stop listening for
  /// [listener] The specific listener function to remove
  /// 
  /// Returns true if the listener was found and removed, false otherwise
  bool removeEventListener<T>(WuKongEvent event, WuKongEventListener<T> listener) {
    final listeners = _listeners[event];
    if (listeners != null) {
      final removed = listeners.remove(listener);
      if (removed) {
        developer.log('Removed event listener for $event. Remaining listeners: ${listeners.length}');
      } else {
        developer.log('Warning: Listener not found for event: $event');
      }
      return removed;
    } else {
      developer.log('Warning: Attempted to remove listener for unknown event: $event');
      return false;
    }
  }
  
  /// Removes all event listeners for the specified event type
  /// 
  /// [event] The event type to clear all listeners for
  /// 
  /// Returns the number of listeners that were removed
  int removeAllEventListeners(WuKongEvent event) {
    final listeners = _listeners[event];
    if (listeners != null) {
      final count = listeners.length;
      listeners.clear();
      developer.log('Removed all $count listeners for event: $event');
      return count;
    } else {
      developer.log('Warning: Attempted to clear listeners for unknown event: $event');
      return 0;
    }
  }
  
  /// Removes all event listeners for all event types
  /// 
  /// Returns the total number of listeners that were removed
  int clearAllEventListeners() {
    int totalRemoved = 0;
    for (final event in WuKongEvent.values) {
      totalRemoved += removeAllEventListeners(event);
    }
    developer.log('Cleared all event listeners. Total removed: $totalRemoved');
    return totalRemoved;
  }
  
  /// Emits an event to all registered listeners
  /// 
  /// [event] The event type to emit
  /// [data] The data to pass to the listeners
  void emit<T>(WuKongEvent event, T data) {
    final listeners = _listeners[event];
    if (listeners != null && listeners.isNotEmpty) {
      developer.log('Emitting event $event to ${listeners.length} listeners');
      
      // Create a copy of the listeners list to avoid modification during iteration
      final listenersCopy = List<Function>.from(listeners);
      
      for (final listener in listenersCopy) {
        try {
          // Call the listener with the data
          if (listener is WuKongEventListener<T>) {
            listener(data);
          } else {
            // Fallback for dynamic listeners
            listener(data);
          }
        } catch (error, stackTrace) {
          developer.log(
            'Error in event listener for $event: $error',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    } else {
      developer.log('No listeners registered for event: $event');
    }
  }
  
  /// Gets the number of listeners for a specific event type
  /// 
  /// [event] The event type to count listeners for
  /// 
  /// Returns the number of listeners registered for the event
  int getListenerCount(WuKongEvent event) {
    return _listeners[event]?.length ?? 0;
  }
  
  /// Gets the total number of listeners across all event types
  /// 
  /// Returns the total number of listeners registered
  int getTotalListenerCount() {
    return _listeners.values.fold(0, (sum, listeners) => sum + listeners.length);
  }
  
  /// Checks if there are any listeners for a specific event type
  /// 
  /// [event] The event type to check
  /// 
  /// Returns true if there are listeners for the event, false otherwise
  bool hasListeners(WuKongEvent event) {
    return getListenerCount(event) > 0;
  }
  
  /// Gets a list of all event types that have listeners
  /// 
  /// Returns a list of event types that have at least one listener
  List<WuKongEvent> getEventsWithListeners() {
    return _listeners.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();
  }
}
