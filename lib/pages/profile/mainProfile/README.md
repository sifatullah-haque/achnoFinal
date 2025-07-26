# Profile Modular Structure

This directory contains the modularized profile components for better maintainability and code organization. The profile functionality includes user profile display, posts and reviews management, follow/unfollow functionality, audio bio playback, and profile editing capabilities.

## Structure

```
lib/pages/profile/mainProfile/
├── profile.dart                    # Main profile widget (entry point)
├── README.md                       # This documentation file
└── components/                     # Modular components
    ├── profile_controller.dart     # Business logic and state management
    ├── profile_view.dart           # Main UI component
    ├── profile_states.dart         # Loading, empty, and error states
    └── profile_widgets.dart        # Reusable UI components
```

## Components Overview

### 1. ProfileController (`components/profile_controller.dart`)
**Purpose**: Centralized state management and business logic for the profile page
- Manages user data, posts, and reviews
- Handles follow/unfollow functionality
- Manages audio playback for posts and audio bio
- Provides data loading and refresh capabilities
- Handles user authentication and permissions

**Key Features**:
- Extends `ChangeNotifier` for reactive state management
- Firestore integration for user data, posts, and reviews
- Audio playback management with Flutter Sound
- Follow/unfollow functionality with real-time updates
- Error handling and loading states
- User rating calculation and statistics

### 2. ProfileView (`components/profile_view.dart`)
**Purpose**: Main UI component that renders the profile page
- Handles the overall layout and structure
- Manages tab navigation between posts and reviews
- Integrates with the controller for state management
- Provides navigation to edit profile and settings

**Key Features**:
- Responsive design with ScreenUtil
- Custom scroll view with sliver app bar
- Tab navigation with persistent header
- Background gradient and decorative elements
- Navigation integration with GoRouter

### 3. ProfileStates (`components/profile_states.dart`)
**Purpose**: State-specific UI components for different scenarios
- Loading state widget
- Empty states for posts and reviews
- Error state widget with retry functionality
- Profile not found state
- Network error and offline states
- Permission request states

**Key Features**:
- Consistent error handling UI
- User-friendly empty states with call-to-action buttons
- Skeleton loading animations
- Retry functionality for error recovery
- Localized messages and icons

### 4. ProfileWidgets (`components/profile_widgets.dart`)
**Purpose**: Reusable UI components for profile functionality
- Profile header with user info and actions
- Post cards with audio playback
- Review cards with ratings and audio reviews
- Tab bar component
- Statistics display widgets

**Key Features**:
- Modular and reusable components
- Audio playback integration
- Rating display with star indicators
- Follow/unfollow button states
- Responsive design patterns

## Usage

### Basic Usage
```dart
import 'package:achno/pages/profile/mainProfile/profile.dart';

// Display current user's profile
Profile()

// Display specific user's profile
Profile(userId: 'user_id_here')
```

### Advanced Usage with Custom Controller
```dart
import 'package:achno/pages/profile/mainProfile/components/profile_controller.dart';
import 'package:achno/pages/profile/mainProfile/components/profile_view.dart';

// Create custom controller
final controller = ProfileController();

// Use with custom view
ProfileView(
  userId: 'user_id',
  controller: controller,
)
```

### Direct Component Usage
```dart
import 'package:achno/pages/profile/mainProfile/components/profile_widgets.dart';

// Use individual widgets
ProfileWidgets.buildProfileHeader(
  context: context,
  userData: userData,
  isCurrentUser: true,
  isFollowing: false,
  onFollowToggle: () {},
  onEditProfile: () {},
  onSettings: () {},
  onAudioBioPlay: () {},
  isAudioPlaying: false,
  currentlyPlayingId: '',
)
```

## Profile Features

### 1. User Information Display
- Profile picture with fallback avatar
- User name and username
- Bio text with directionality support
- Location information
- Activity and professional status
- Follower/following counts
- User rating and review count

### 2. Audio Bio
- Audio recording playback
- Visual progress indicators
- Play/stop controls
- Background audio session management
- Error handling for audio playback

### 3. Posts Management
- User's posts display
- Audio message playback
- Text content with directionality
- Activity and location tags
- Like and interaction buttons
- Timestamp formatting

### 4. Reviews System
- User reviews display
- Star rating visualization
- Text and audio reviews
- Reviewer information
- Review timestamps
- Average rating calculation

### 5. Follow/Unfollow Functionality
- Real-time follow status updates
- Follower count synchronization
- Follow/unfollow button states
- Cross-user profile viewing
- Permission-based actions

## Audio Features

### Audio Bio Playback
- Single audio file playback
- Progress tracking and visualization
- Background audio session management
- Error handling and recovery
- Play/stop toggle functionality

### Post Audio Messages
- Individual post audio playback
- Multiple audio source handling
- Progress indicators
- Concurrent audio management
- Memory-efficient playback

### Review Audio Messages
- Audio review playback
- Rating and audio combination
- Reviewer audio messages
- Consistent audio controls
- Error state handling

## State Management

### Loading States
- Initial data loading
- Refresh operations
- Skeleton loading animations
- Progressive data loading
- Background data updates

### Error States
- Network connectivity issues
- Permission errors
- Data loading failures
- Audio playback errors
- User not found scenarios

### Empty States
- No posts available
- No reviews available
- Empty profile data
- No followers/following
- Inactive user profiles

## Navigation Integration

### Profile Actions
- Edit profile navigation
- Settings page access
- Back navigation
- Profile options menu
- Share profile functionality

### Cross-User Navigation
- View other user profiles
- Follow/unfollow actions
- Block user functionality
- Report user options
- Profile sharing

## Performance Considerations

### Data Loading
- Efficient Firestore queries
- Pagination for large datasets
- Caching strategies
- Background data updates
- Optimistic UI updates

### Audio Optimization
- Audio file compression
- Streaming playback
- Background session management
- Memory leak prevention
- Resource cleanup

### UI Performance
- Efficient widget rebuilding
- Lazy loading for lists
- Image optimization
- Smooth scrolling
- Responsive design

## Security Features

### Data Validation
- User input sanitization
- Permission-based access
- Data ownership verification
- Secure audio file handling
- Cross-user data protection

### Authentication
- User session validation
- Profile access control
- Follow relationship verification
- Admin privilege checks
- Secure data transmission

## Future Enhancements

Potential improvements for the modular structure:

1. **Enhanced Audio Features**
   - Voice-to-text transcription
   - Audio message editing
   - Background noise reduction
   - Audio effects and filters
   - Audio message reactions

2. **Advanced Profile Features**
   - Profile customization themes
   - Custom profile layouts
   - Profile verification badges
   - Profile analytics
   - Profile privacy settings

3. **Social Features**
   - Profile sharing improvements
   - Profile recommendations
   - Mutual connections display
   - Profile visit tracking
   - Social media integration

4. **Content Management**
   - Post organization and filtering
   - Review moderation tools
   - Content scheduling
   - Draft management
   - Content analytics

5. **Performance Optimizations**
   - Advanced caching strategies
   - Lazy loading improvements
   - Background sync enhancements
   - Offline support
   - Progressive web app features

6. **User Experience**
   - Enhanced animations
   - Custom themes
   - Accessibility improvements
   - Multi-language support
   - Dark mode support

## Testing Strategy

### Unit Tests
- Controller logic testing
- State management validation
- Audio functionality testing
- Data transformation testing
- Error handling validation

### Widget Tests
- UI component testing
- User interaction testing
- State change testing
- Navigation testing
- Error state testing

### Integration Tests
- End-to-end profile flow
- Audio playback integration
- Follow/unfollow functionality
- Cross-user interactions
- Data synchronization

## Dependencies

### Core Dependencies
- `flutter_sound`: Audio recording and playback
- `audio_session`: Audio session management
- `cloud_firestore`: Real-time database
- `provider`: State management
- `go_router`: Navigation

### UI Dependencies
- `flutter_screenutil`: Responsive design
- `flutter_rating_bar`: Rating display
- `timeago`: Time formatting

### Utility Dependencies
- `achno/widgets/directionality_text`: Text direction support
- `achno/utils/activity_icon_helper`: Activity icons
- `achno/config/theme`: App theming
- `achno/l10n/app_localizations`: Localization

## Contributing

When contributing to the profile module:

1. Follow the existing modular structure
2. Add comprehensive error handling
3. Include proper documentation
4. Write unit tests for new functionality
5. Ensure responsive design compatibility
6. Test on multiple devices and platforms
7. Follow the established naming conventions
8. Update this README for new features
9. Maintain audio performance standards
10. Ensure accessibility compliance 