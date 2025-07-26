# Homepage Modular Structure

This directory contains the modularized homepage components for better maintainability and code organization.

## Structure

```
lib/pages/homepage/
├── homepage.dart                 # Main homepage widget (entry point)
├── homepageConst.dart           # Constants and configurations
├── README.md                    # This documentation file
└── components/                  # Modular components
    ├── homepage_controller.dart # Business logic and state management
    ├── homepage_view.dart       # Main UI component
    ├── homepage_filters.dart    # Filter-related widgets
    ├── homepage_states.dart     # Empty, error, and loading states
    └── filter_bottom_sheet.dart # Filter modal component
```

## Components Overview

### 1. HomepageController (`components/homepage_controller.dart`)
**Purpose**: Centralized state management and business logic
- Manages all state variables (posts, filters, audio, location, etc.)
- Handles data fetching and API calls
- Manages audio playback functionality
- Handles location services and distance calculations
- Provides filter logic and post filtering

**Key Features**:
- Extends `ChangeNotifier` for reactive state management
- Audio player initialization and management
- Location services integration
- Distance calculation between cities
- Post filtering and search functionality

### 2. HomepageView (`components/homepage_view.dart`)
**Purpose**: Main UI component that renders the homepage
- Handles the overall layout and structure
- Manages animations and transitions
- Renders posts list and search bar
- Integrates with the controller for state management

**Key Features**:
- Responsive design with ScreenUtil
- Animated transitions
- Integration with filter components
- Post list rendering with PostCard widgets

### 3. HomepageFilters (`components/homepage_filters.dart`)
**Purpose**: Reusable filter widgets and components
- Filter indicator widget
- Distance filter chips
- Activity filter chips
- Type filter chips
- City dropdown component

**Key Features**:
- Static methods for building filter widgets
- Consistent styling and behavior
- Localization support
- Reusable across different contexts

### 4. HomepageStates (`components/homepage_states.dart`)
**Purpose**: State-specific UI components
- Empty state widget (no posts)
- Error state widget (loading failed)
- Loading state widget
- No results state widget (filtered results empty)

**Key Features**:
- Consistent error handling UI
- User-friendly empty states
- Action buttons for recovery
- Localized messages

### 5. FilterBottomSheet (`components/filter_bottom_sheet.dart`)
**Purpose**: Modal bottom sheet for filter configuration
- Complete filter interface
- Post type selection
- City selection
- Distance filters
- Activity filters

**Key Features**:
- Modal presentation
- Stateful builder for real-time updates
- Apply and clear functionality
- Responsive design

## Usage

### Basic Usage
```dart
import 'package:achno/pages/homepage/homepage.dart';

// In your app
Homepage(
  onNavigateToAddPost: () {
    // Navigate to add post screen
  },
)
```

### Advanced Usage with Custom Controller
```dart
import 'package:achno/pages/homepage/components/homepage_controller.dart';
import 'package:achno/pages/homepage/components/homepage_view.dart';

// Create custom controller
final controller = HomepageController();

// Use with custom view
HomepageView(
  controller: controller,
  onNavigateToAddPost: () {
    // Custom navigation logic
  },
)
```

## Benefits of Modular Structure

1. **Maintainability**: Each component has a single responsibility
2. **Reusability**: Components can be reused in different contexts
3. **Testability**: Individual components can be tested in isolation
4. **Readability**: Code is organized and easy to understand
5. **Scalability**: Easy to add new features or modify existing ones
6. **Separation of Concerns**: UI logic separated from business logic

## State Management

The homepage uses a `ChangeNotifier` pattern with the `HomepageController`:
- All state is managed centrally in the controller
- UI components listen to state changes automatically
- State updates trigger UI rebuilds efficiently
- Provider pattern for dependency injection

## Audio Management

Audio functionality is handled by the controller:
- Audio player initialization
- Playback control
- Duration caching
- Progress tracking
- Error handling

## Location Services

Location functionality includes:
- GPS location fetching
- Permission handling
- City-based distance calculations
- Location updates
- Error handling for location services

## Filtering System

The filtering system supports:
- City-based filtering
- Activity-based filtering
- Post type filtering
- Distance-based filtering
- Combined filter logic
- Filter state persistence

## Performance Considerations

- Audio durations are cached to avoid repeated calculations
- Distance calculations are precomputed and cached
- Posts are filtered efficiently using Dart's `where` method
- UI updates are optimized with `ChangeNotifier`
- Animations are properly disposed to prevent memory leaks

## Future Enhancements

Potential improvements for the modular structure:
1. Add unit tests for each component
2. Implement more advanced caching strategies
3. Add offline support
4. Implement search functionality
5. Add more filter options
6. Optimize performance for large post lists 