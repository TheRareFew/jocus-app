# Plan to Fix HLS Handling in the JOCUS App

Below is a step-by-step plan to resolve the issues with HLS file generation, storage, and frontend playback.

## ✅ Completed Changes

1. **Unified Firestore Field Names for Video URLs**  
   - Changed `videoUrl` to `storageUrl` in `hls_transcoder.py` to match the field set by `video_upload_service.dart`.
   - Verified that the field names now match across both files.

2. **Improved Trigger Logic in Cloud Functions**  
   - Renamed function from `on_video_created` to `on_video_updated` to match its trigger type.
   - Added explicit status check to only process videos with `status == 'processing'`.
   - Function now properly triggers on document updates.

3. **Simplified HLS Storage Path**  
   - Changed from complex URL-based path to simple `hls/{videoId}` format.
   - Updated `create_hls_stream` to use the provided path directly.
   - This makes paths more predictable and easier to manage.

## 🔄 Remaining Tasks

4. **Verify Public Access to HLS Files**  
   - Current code sets `predefined_acl='publicRead'` which is correct.
   - Need to verify Firebase Storage security rules allow this access.
   - Action needed: Check and update storage rules if necessary.

5. **Frontend: Test HLS URL Usage**  
   - Current code in `feed_screen.dart` already checks for `hlsUrl`.
   - Need to verify that the video player can handle HLS streams.
   - Action needed: Test with actual HLS content and consider using a more robust player if needed.

6. **Testing Plan**  
   - Upload a new video and verify:
     1. Status changes to "processing"
     2. Cloud Function triggers
     3. HLS files are generated in correct location
     4. Document is updated with `hlsUrl`
     5. Frontend player successfully plays the HLS stream

7. **Edge Cases to Monitor**  
   - Large video uploads
   - Slow transcoding times
   - Memory usage in Cloud Functions
   - Network interruptions during upload/processing

## Next Steps
1. Check Firebase Storage security rules
2. Test the complete flow with a real video upload
3. Monitor Cloud Function logs for any errors
4. Consider implementing error recovery mechanisms