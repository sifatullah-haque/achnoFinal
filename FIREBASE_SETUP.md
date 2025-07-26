# Firebase Setup Guide

## Issue
The notification page is stuck in a loading state due to Firestore permission errors. The error messages indicate:
- `PERMISSION_DENIED: Missing or insufficient permissions`
- The app doesn't have proper permissions to read from the Firestore database

## Solution
The Firestore security rules need to be updated to include permissions for the notifications subcollection.

## Steps to Fix

### 1. Install Firebase CLI (if not already installed)
```bash
npm install -g firebase-tools
```

### 2. Login to Firebase
```bash
firebase login
```

### 3. Deploy the Updated Rules
```bash
firebase deploy --only firestore:rules
```

## Updated Firestore Rules

The `firebase.rules` file has been updated to include permissions for the notifications subcollection:

```javascript
// Users collection rules
match /users/{userId} {
  allow read: if isAuthenticated();
  allow create: if 
    request.auth.uid == userId &&
    request.resource.data.keys().hasAll(['email', 'firstName', 'lastName', 'city', 'userType', 'isProfessional']) &&
    request.resource.data.email is string &&
    request.resource.data.firstName is string &&
    request.resource.data.lastName is string &&
    request.resource.data.city is string &&
    request.resource.data.userType in ['Client', 'Professional'] &&
    request.resource.data.isProfessional is bool;
  allow update: if isOwner(userId);
  allow delete: if isOwner(userId);
  
  // Notifications subcollection rules
  match /notifications/{notificationId} {
    allow read: if isOwner(userId);
    allow create: if isAuthenticated();
    allow update: if isOwner(userId);
    allow delete: if isOwner(userId);
  }
}
```

## Alternative Manual Setup

If you can't use Firebase CLI, you can manually update the rules in the Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Click on "Rules" tab
5. Replace the existing rules with the content from `firebase.rules`
6. Click "Publish"

## Testing

After deploying the rules:

1. Restart the app
2. Navigate to the notification page
3. The loading should stop and either show notifications or an empty state
4. Try the "Send Test Notification" button to create a test notification

## Debug Information

The notification controller now includes better error handling and debug information:

- Authentication checks
- Detailed error messages
- Debug logging for troubleshooting
- Test notification functionality

## Common Issues

1. **Still Loading**: Check if user is authenticated
2. **Permission Errors**: Verify Firestore rules are deployed
3. **Network Issues**: Check internet connection
4. **Firebase Configuration**: Verify `google-services.json` is up to date

## Next Steps

Once the permissions are fixed:
1. Test the notification functionality
2. Verify real-time updates work
3. Test all notification interactions (mark as read, delete, etc.)
4. Monitor for any remaining issues 