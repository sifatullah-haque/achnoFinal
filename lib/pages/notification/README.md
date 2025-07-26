# Notification Page

## Overview

The Notification page provides a comprehensive notification management system for the Achno app. It displays real-time notifications, allows users to interact with them, and provides various management options.

## Architecture

The notification page follows a modular architecture pattern similar to the Add Post and Chat pages, with clear separation of concerns:

```
lib/pages/notification/
├── notification.dart                 # Main entry point
├── README.md                        # This documentation
└── components/
    ├── notification_controller.dart  # Business logic and state management
    ├── notification_states.dart      # State definitions
    ├── notification_view.dart        # UI logic and controller integration
    └── notification_widgets.dart     # Reusable UI components
```

## Components

### 1. NotificationController (`notification_controller.dart`)

**Purpose**: Manages all business logic, state, and data operations for the notification page.

**Key Responsibilities**:
- Real-time notification stream management
- Notification CRUD operations (mark as read, delete, etc.)
- Error handling and loading states
- User interaction handling
- Navigation logic

**Key Methods**:
```dart
// Initialization
Future<void> initialize()

// Data operations
Future<void> refreshNotifications()
Future<void> markNotificationAsRead(String notificationId)
Future<void> markAllNotificationsAsRead()
Future<void> deleteNotification(String notificationId)
Future<void> clearAllNotifications()

// User interactions
void handleNotificationTap(BuildContext context, NotificationModel notification)
Future<void> sendTestNotification(BuildContext context)

// State management
void setErrorMessage(String message)
void clearErrorMessage()
void setLoading(bool loading)
```

**State Properties**:
- `isLoading`: Loading state indicator
- `allNotifications`: List of all notifications
- `errorMessage`: Current error message
- `isAnimating`: Animation state
- `notificationsStream`: Real-time notification stream

### 2. NotificationStates (`notification_states.dart`)

**Purpose**: Defines all possible states the notification page can be in.

**State Classes**:
- `NotificationInitialState`: Initial state
- `NotificationLoadingState`: Loading state
- `NotificationLoadedState`: Loaded with notifications
- `NotificationEmptyState`: No notifications
- `NotificationErrorState`: Error state with retry option
- `NotificationRefreshingState`: Refreshing state
- `NotificationMarkingAsReadState`: Marking notification as read
- `NotificationMarkingAllAsReadState`: Marking all as read
- `NotificationDeletingState`: Deleting notification
- `NotificationClearingAllState`: Clearing all notifications
- `NotificationSendingTestState`: Sending test notification
- `NotificationTestSentState`: Test notification sent
- `NotificationTestErrorState`: Test notification error

### 3. NotificationView (`notification_view.dart`)

**Purpose**: Handles UI logic and connects the controller with widgets.

**Key Features**:
- Animation management (fade transitions)
- Provider setup for state management
- StreamBuilder integration for real-time updates
- Error and loading state handling
- RefreshIndicator integration

**Structure**:
```dart
class NotificationView extends StatefulWidget {
  // Animation controller setup
  // Provider integration
  // StreamBuilder for real-time updates
}
```

### 4. NotificationWidgets (`notification_widgets.dart`)

**Purpose**: Contains all reusable UI components for the notification page.

**Key Widgets**:
- `buildAppBar()`: Custom app bar with actions
- `buildBackground()`: Decorative background patterns
- `buildEmptyState()`: Empty state UI
- `buildErrorState()`: Error state UI
- `buildNotificationItem()`: Individual notification card
- `_buildLeadingAvatar()`: Notification avatar/icon
- `_buildActionButton()`: Action buttons (follow, etc.)
- `_buildOptionsSheet()`: Options bottom sheet
- `_showNotificationOptions()`: Notification options modal

**Helper Methods**:
- `_getNotificationTypeText()`: Localized notification type text
- `_getNotificationAccentColor()`: Color based on notification type
- `_getNotificationTypeIcon()`: Icon based on notification type

## Features

### 1. Real-time Notifications
- Stream-based real-time updates
- Automatic refresh on new notifications
- Pull-to-refresh functionality

### 2. Notification Types
- **Message**: Chat notifications
- **Like**: Post like notifications
- **Comment**: Post comment notifications
- **Follow**: User follow notifications
- **Mention**: User mention notifications
- **System**: System announcements

### 3. Interaction Options
- **Tap**: Mark as read and navigate
- **Long Press**: Show options menu
- **Swipe**: Delete notification
- **Action Buttons**: Follow back, etc.

### 4. Management Features
- Mark individual notifications as read
- Mark all notifications as read
- Delete individual notifications
- Clear all notifications
- Send test notifications
- Notification settings access

### 5. Visual Design
- Modern card-based design
- Color-coded notification types
- Smooth animations and transitions
- Responsive layout
- Accessibility support

## Usage

### Basic Implementation
```dart
import 'package:achno/pages/notification/notification.dart';

// In your app
NotificationScreen()
```

### Custom Controller Usage
```dart
import 'package:achno/pages/notification/components/notification_controller.dart';

final controller = NotificationController();
await controller.initialize();

// Listen to state changes
controller.addListener(() {
  // Handle state changes
});
```

### Custom Widget Usage
```dart
import 'package:achno/pages/notification/components/notification_widgets.dart';

// Use individual widgets
NotificationWidgets.buildNotificationItem(
  context,
  notification,
  index,
  controller,
)
```

## State Management

The notification page uses Provider pattern for state management:

1. **Controller**: Extends `ChangeNotifier` for state updates
2. **View**: Uses `ChangeNotifierProvider` and `Consumer`
3. **Widgets**: Access controller through context

### State Flow
```
User Action → Controller Method → State Update → UI Refresh
```

## Error Handling

The notification page implements comprehensive error handling:

1. **Network Errors**: Retry functionality
2. **Permission Errors**: User guidance
3. **Service Errors**: Fallback mechanisms
4. **UI Errors**: Graceful degradation

## Performance Considerations

1. **Stream Management**: Proper disposal of stream subscriptions
2. **Memory Management**: Efficient list operations
3. **Animation Optimization**: Hardware acceleration
4. **Image Loading**: Cached network images
5. **List Optimization**: Efficient ListView.builder usage

## Testing

### Unit Tests
- Controller logic testing
- State management testing
- Service integration testing

### Widget Tests
- UI component testing
- User interaction testing
- State change testing

### Integration Tests
- End-to-end notification flow
- Real-time updates testing
- Error scenario testing

## Dependencies

### Core Dependencies
- `flutter`: Core Flutter framework
- `provider`: State management
- `flutter_screenutil`: Responsive design

### Feature Dependencies
- `timeago`: Time formatting
- `achno/models/notification_model`: Notification data model
- `achno/services/notification_service`: Notification service
- `achno/config/theme`: App theme
- `achno/l10n/app_localizations`: Localization

## Localization

The notification page supports multiple languages through the `AppLocalizations` class:

- English (en)
- Arabic (ar)
- French (fr)

### Localized Strings
- Notification titles and messages
- Action button labels
- Error messages
- Empty state messages

## Accessibility

The notification page includes accessibility features:

1. **Semantic Labels**: Proper accessibility labels
2. **Screen Reader Support**: Descriptive text
3. **Keyboard Navigation**: Tab order support
4. **Color Contrast**: WCAG compliant colors
5. **Touch Targets**: Minimum 44x44 points

## Future Enhancements

### Planned Features
1. **Notification Filters**: Filter by type, date, etc.
2. **Notification Groups**: Group similar notifications
3. **Custom Sounds**: User-defined notification sounds
4. **Snooze Functionality**: Temporarily hide notifications
5. **Bulk Actions**: Multi-select operations

### Technical Improvements
1. **Offline Support**: Local notification storage
2. **Push Notifications**: Real-time push notifications
3. **Analytics**: User interaction tracking
4. **Performance**: Further optimization
5. **Testing**: Comprehensive test coverage

## Contributing

When contributing to the notification page:

1. **Follow Architecture**: Maintain modular structure
2. **Add Tests**: Include unit and widget tests
3. **Update Documentation**: Keep README current
4. **Follow Style Guide**: Use consistent code style
5. **Handle Errors**: Implement proper error handling

## Troubleshooting

### Common Issues

1. **Notifications Not Loading**
   - Check network connectivity
   - Verify service permissions
   - Check Firebase configuration

2. **Real-time Updates Not Working**
   - Verify stream subscription
   - Check Firebase rules
   - Ensure proper disposal

3. **UI Not Updating**
   - Check Provider setup
   - Verify notifyListeners() calls
   - Check widget rebuild conditions

### Debug Tips

1. **Enable Debug Logs**: Check console for errors
2. **Test Stream**: Verify notification stream
3. **Check State**: Monitor controller state
4. **UI Inspector**: Use Flutter Inspector
5. **Performance Profiler**: Monitor performance

## Related Files

- `lib/models/notification_model.dart`: Notification data model
- `lib/services/notification_service.dart`: Notification service
- `lib/providers/notification_provider.dart`: Global notification provider
- `lib/config/theme.dart`: App theme configuration
- `lib/l10n/`: Localization files 