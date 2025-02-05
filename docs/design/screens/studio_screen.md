# Studio Screen Implementation Plan

## Overview
The Studio Screen will handle video upload functionality, integrating with OpenShot API (hosted on EC2) for video editing and Firebase services for storage and data management. In cases where OpenShot API is not accessible, the system will fall back to raw video upload functionality.

## Implementation Checklist

### Firebase Setup and Configuration
- [x] Import necessary Firebase dependencies in the Flutter app
  - firebase_storage
  - cloud_firestore
  - firebase_core
- [ ] Create Firebase storage rules for video uploads
- [x] Define Firestore collection structure for video metadata
  ```
  videos/
    ├── videoId/
    │   ├── title: String
    │   ├── description: String
    │   ├── uploadDate: Timestamp
    │   ├── duration: Number
    │   ├── storageUrl: String
    │   ├── thumbnailUrl: String
    │   ├── userId: String
    │   ├── status: String (processing/ready/failed)
    │   └── metadata: Map
  ```

### UI Components
- [x] Create StudioScreen widget
- [x] Implement responsive layout with the following sections:
  - [x] Video upload area with drag-and-drop support
  - [x] Upload progress indicator
  - [x] Video metadata form (title, description, etc.)
  - [x] Preview section for uploaded video
  - [x] Status indicator for processing state
- [x] Add error handling UI components
- [x] Implement loading states and animations

### OpenShot API Integration
- [x] Create OpenShotService class
- [x] Implement the following API methods:
  - [x] uploadVideoForEditing(File video)
  - [x] getEditingStatus(String projectId)
  - [x] downloadProcessedVideo(String projectId)
- [x] Add error handling and retry logic
- [x] Implement background processing status checks

### Video Upload Flow
- [x] Create VideoUploadService class
- [x] Implement video file validation
  - [x] Check file size limits
  - [ ] Verify supported formats
  - [ ] Validate video duration
- [x] Add video compression (if needed)
- [x] Implement the upload pipeline:
  1. [x] Local video selection
  2. [x] Pre-upload validation
  3. [x] Check OpenShot API availability
  4. [x] If OpenShot available:
     - [x] Upload to OpenShot API
     - [x] Monitor processing status
     - [x] Download processed video
     - [x] Upload to Firebase Storage
  5. [x] If OpenShot unavailable:
     - [x] Show notification to user about raw upload
     - [x] Upload raw video directly to Firebase Storage
  6. [x] Create Firestore document
  7. [x] Update UI with success/failure

### State Management
- [x] Create VideoUploadState class
- [x] Implement the following states:
  - [x] Initial
  - [x] Validating
  - [x] UploadingToOpenShot
  - [x] Processing
  - [x] DownloadingProcessed
  - [x] UploadingToFirebase
  - [x] Completed
  - [x] Error
- [x] Add state management solution (Provider)

### Error Handling
- [x] Implement error handling for:
  - [x] Network failures
  - [x] API errors
  - [x] File system errors
  - [x] Firebase upload failures
  - [x] Invalid file types
  - [x] Size limit exceeded
- [x] Add retry mechanisms for recoverable errors
- [x] Implement error reporting and logging

### Performance Optimization (Optional)
- [ ] Implement chunked upload for large files
- [x] Add upload cancellation support
- [ ] Optimize memory usage during upload
- [ ] Add upload queue for multiple files
- [ ] Implement background upload support

### User Experience
- [x] Add upload progress tracking
- [x] Implement estimated time remaining
- [x] Add upload speed indicator
- [x] Create informative error messages
  - [x] OpenShot API unavailability message
  - [x] Upload failure messages
  - [x] Processing status messages
- [x] Add success notifications
- [x] Implement upload history section
- [x] Add indicator for raw vs processed video uploads

### Documentation
- [x] Add inline code documentation
- [x] Create API integration guide
- [x] Document state management flow
- [x] Add error handling documentation
- [x] Create user guide for video upload
- [x] Document raw upload fallback behavior

## Dependencies Required
```yaml
dependencies:
  firebase_storage: ^11.5.6
  cloud_firestore: ^4.13.6
  file_picker: ^6.1.1
  http: ^1.1.2
  path: ^1.8.3
  provider: ^6.1.1
  video_compress: ^3.1.2
```

## Notes
- The system will attempt to use OpenShot API for video processing by default
- If OpenShot API is unavailable (timeout, connection error, or service down):
  - Users will be notified that the video will be uploaded without processing
  - Raw videos will be uploaded directly to Firebase Storage
  - Video metadata will include a flag indicating whether the video was processed
  - Users can request processing later when OpenShot API becomes available (future enhancement)

## Remaining Tasks
1. Create Firebase storage rules for video uploads
2. Implement video format validation
3. Add video duration validation
4. Optional performance optimizations:
   - Chunked uploads for large files
   - Memory usage optimization
   - Multiple file upload queue
   - Background upload support 