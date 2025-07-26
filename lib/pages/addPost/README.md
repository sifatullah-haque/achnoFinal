# AddPost Modular Structure

This directory contains the modularized addPost components for better maintainability and code organization. The addPost functionality includes voice recording, text input, location selection, activity categorization, and post submission with admin approval workflow.

## Structure

```
lib/pages/addPost/
├── addPost.dart                    # Main entry point widget
├── README.md                       # This documentation file
└── components/                     # Modular components
    ├── add_post_controller.dart    # Business logic and state management
    ├── add_post_view.dart          # Main UI component
    ├── add_post_widgets.dart       # Reusable UI widgets
    └── add_post_states.dart        # State-specific UI components
```

## Components Overview

### 1. AddPostController (`components/add_post_controller.dart`)
**Purpose**: Centralized state management and business logic for the addPost functionality
- Manages form state and validation
- Handles audio recording and playback
- Manages Google Places API integration
- Provides post submission capabilities
- Handles user permissions and initialization

**Key Features**:
- Extends `ChangeNotifier` for reactive state management
- Audio recording with real-time visualization
- Google Places autocomplete for city selection
- Activity categorization with localization support
- Post duration management
- Firebase integration for post creation
- Permission handling for microphone access
- User profile integration for default values

### 2. AddPostView (`components/add_post_view.dart`)
**Purpose**: Main UI component that orchestrates the addPost interface
- Handles the overall layout and structure
- Manages animations and transitions
- Integrates all sub-components
- Provides navigation and dialog management

**Key Features**:
- Responsive design with ScreenUtil
- Animated transitions and loading states
- Glass morphism effects with backdrop blur
- Integration with all sub-components
- Success dialog management
- Navigation handling after post submission

### 3. AddPostWidgets (`components/add_post_widgets.dart`)
**Purpose**: Reusable UI widgets for the addPost functionality
- Voice recording interface with visualization
- Duration selector with horizontal scrolling
- Message input with optional text
- City selector with autocomplete
- Activity selection grid and dropdown

**Key Features**:
- Voice recording with waveform visualization
- Audio playback with progress tracking
- Duration selection with icons and localization
- Google Places autocomplete integration
- Activity grid with icons and selection states
- Responsive design patterns
- Consistent styling across components

### 4. AddPostStates (`components/add_post_states.dart`)
**Purpose**: State-specific UI components for different scenarios
- Error message display
- Loading state indicators
- Permission denied states
- Success state notifications
- Network error handling
- Validation error display

**Key Features**:
- Consistent error handling UI
- User-friendly state messages
- Retry functionality for error recovery
- Localized messages and icons
- Color-coded state indicators

## Usage

### Basic Usage
```dart
import 'package:achno/pages/addPost/addPost.dart';

// In your app
Addpost()
```

### Advanced Usage with Custom Controller
```dart
import 'package:achno/pages/addPost/components/add_post_controller.dart';
import 'package:achno/pages/addPost/components/add_post_view.dart';

// Create custom controller
final controller = AddPostController();

// Use with custom view
AddPostView(
  controller: controller,
)
```

### Direct Component Usage
```dart
import 'package:achno/pages/addPost/components/add_post_widgets.dart';
import 'package:achno/pages/addPost/components/add_post_states.dart';

// Use individual widgets
AddPostWidgets.buildVoiceRecordingSection(context, controller, 'Record Voice');
AddPostStates.buildErrorMessage(context, 'Error message');
```

## Post Types

The addPost system supports multiple post types:

### 1. Professional Offers
- Service providers can post offers
- Automatic activity detection from profile
- Professional verification integration
- Service-specific categorization

### 2. Client Requests
- Users can post service requests
- Location-based matching
- Duration-based expiry
- Request categorization

## Audio Features

### Recording
- Microphone permission handling
- Real-time audio level visualization
- Recording duration tracking (max 60 seconds)
- Cancel and retry functionality
- Audio file compression and validation

### Playback
- Audio session management
- Progress tracking and display
- Background playback support
- Multiple audio source handling

### Visualization
- Real-time waveform display during recording
- Animated playback visualization
- Consistent styling across components
- Responsive design patterns

## Location Features

### Google Places Integration
- Real-time city search and autocomplete
- Morocco-specific location filtering
- City name normalization
- Address parsing and extraction

### Geolocation
- Current location detection
- GPS coordinates storage
- Location permission handling
- Fallback mechanisms for location services

## Activity Categorization

### Main Activities
- Plumber, Electrician, Painter
- Carpenter, Mason, Tiler
- Icon-based visual selection
- Grid layout for easy selection

### Additional Activities
- Gardener, Cleaner, Roofer
- Welder, Window Installer, HVAC
- Flooring Installer, Landscaper
- Dropdown selection for less common activities

### Localization Support
- Multi-language activity names
- Dynamic localization switching
- Fallback to English names
- Consistent naming conventions

## Post Duration Management

### Duration Options
- Unlimited (no expiry)
- 48 hours
- 7 days
- 30 days

### Expiry Handling
- Automatic expiry date calculation
- Firestore timestamp integration
- Post status management
- Cleanup mechanisms

## Form Validation

### Required Fields
- Voice recording OR text message
- City selection
- Activity categorization
- User authentication

### Optional Fields
- Additional text details
- Custom activity descriptions
- Location coordinates
- Post duration selection

## Firebase Integration

### Post Creation
- Firestore document creation
- Audio file upload to Firebase Storage
- User post count increment
- Location data storage
- Approval status management

### Data Structure
```json
{
  "userId": "user_id",
  "userName": "User Name",
  "userAvatar": "avatar_url",
  "message": "text_message",
  "audioUrl": "audio_file_url",
  "type": "offer|request",
  "activity": "activity_name",
  "city": "normalized_city_name",
  "createdAt": "timestamp",
  "expiryDate": "timestamp",
  "duration": "duration_option",
  "likes": 0,
  "responses": 0,
  "isLiked": false,
  "userType": "Professional|Client",
  "lastUpdated": "timestamp",
  "approvalStatus": "pending",
  "location": "geopoint",
  "latitude": "latitude",
  "longitude": "longitude"
}
```

## Admin Approval Workflow

### Post Status
- **Pending**: Awaiting admin approval
- **Approved**: Visible on homepage
- **Rejected**: Hidden from users

### Approval Process
- Posts are created with 'pending' status
- Admins review posts in admin panel
- Approved posts become visible to users
- Rejected posts are hidden with feedback

## Error Handling

### Network Errors
- Connection loss detection
- Automatic retry mechanisms
- User-friendly error messages
- Offline state handling

### Permission Errors
- Microphone permission requests
- Location permission handling
- Permission denial handling
- Settings navigation for permissions

### Validation Errors
- Form field validation
- File size limits
- Audio format validation
- Location data validation

### Firebase Errors
- Upload failure handling
- Firestore write errors
- Storage quota exceeded
- Authentication errors

## Performance Considerations

### Audio Optimization
- Audio file compression
- Streaming playback for large files
- Background audio session management
- Memory-efficient visualization

### UI Optimization
- Efficient ChangeNotifier usage
- Selective UI updates
- Memory leak prevention
- Resource cleanup

### Network Optimization
- Efficient API calls
- Request caching
- Offline support
- Bandwidth optimization

## Security Features

### Data Validation
- Input sanitization
- File type validation
- Size limits enforcement
- Malicious content detection

### Authentication
- User session validation
- Post ownership verification
- Secure file uploads
- Permission-based access control

### Privacy
- Location data protection
- User data anonymization
- Secure audio storage
- GDPR compliance considerations

## Future Enhancements

Potential improvements for the modular structure:

1. **Enhanced Audio Features**
   - Voice-to-text transcription
   - Audio message editing
   - Background noise reduction
   - Audio effects and filters

2. **Advanced Location Features**
   - Map-based location selection
   - Service area definition
   - Distance-based matching
   - Location history

3. **Rich Media Support**
   - Image attachments
   - Video messages
   - Document sharing
   - Gallery integration

4. **Smart Categorization**
   - AI-powered activity detection
   - Automatic tagging
   - Smart suggestions
   - Category learning

5. **Advanced Validation**
   - Real-time validation
   - Smart suggestions
   - Auto-completion
   - Context-aware validation

6. **Performance Improvements**
   - Lazy loading
   - Background processing
   - Caching strategies
   - Offline capabilities

## Testing Strategy

### Unit Tests
- Controller logic testing
- State management validation
- Audio functionality testing
- Validation logic testing

### Widget Tests
- UI component testing
- User interaction testing
- State change testing
- Error state testing

### Integration Tests
- End-to-end post creation flow
- Audio recording and playback
- Location selection and validation
- Firebase integration testing

## Dependencies

### Core Dependencies
- `flutter_sound`: Audio recording and playback
- `audio_session`: Audio session management
- `cloud_firestore`: Real-time database
- `firebase_storage`: File storage
- `google_maps_webservice`: Places API integration
- `permission_handler`: Permission management
- `geolocator`: Location services

### UI Dependencies
- `flutter_screenutil`: Responsive design
- `provider`: State management
- `go_router`: Navigation

## Contributing

When contributing to the addPost module:

1. Follow the existing modular structure
2. Add comprehensive error handling
3. Include proper documentation
4. Write unit tests for new functionality
5. Ensure responsive design compatibility
6. Test on multiple devices and platforms
7. Follow the established naming conventions
8. Update this README for new features
9. Maintain backward compatibility
10. Consider performance implications

## Migration Guide

### From Monolithic to Modular
1. Replace direct widget usage with component imports
2. Update state management to use controller
3. Migrate UI logic to appropriate widget classes
4. Update error handling to use state components
5. Test all functionality after migration

### Version Compatibility
- Ensure all dependencies are compatible
- Test with different Flutter versions
- Verify Firebase SDK compatibility
- Check platform-specific requirements 