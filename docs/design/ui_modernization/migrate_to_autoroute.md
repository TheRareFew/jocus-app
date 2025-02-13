# AutoRoute Migration Plan

## Prerequisites
- [ ] Ensure Material 3 migration is complete
- [ ] Verify all navigation animations work with Material 3 transitions

## Implementation Steps

1. **Update Dependencies**  
   - [ ] Add/Update dependency in `pubspec.yaml`:
     ```yaml
     dependencies:
       auto_route: ^9.3.0+1
     ```
   - [ ] Run `flutter pub get`
   - [ ] Verify version in `pubspec.lock`

2. **Create Route Configuration**  
   - [ ] Create `lib/core/routes/app_router.dart`:
     ```dart
     @AdaptiveAutoRouter(
       replaceInRouteName: 'Page,Route',
       routes: <AutoRoute>[
         AutoRoute(
           path: '/',
           page: StudioScreen,
           initial: true,
           children: [
             AutoRoute(
               path: 'camera',
               page: CameraScreen,
             ),
             AutoRoute(
               path: 'structures',
               page: MyComedyStructuresScreen,
             ),
             // Add other routes
           ],
         ),
       ],
     )
     class $AppRouter {}
     ```

3. **Generate Route Code**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Update Navigation Calls**
   - [ ] Replace Navigator calls with AutoRoute:
     ```dart
     // Old
     Navigator.push(context, MaterialPageRoute(...))
     
     // New
     context.router.push(CameraRoute())
     ```

5. **Add Route Guards**
   - [ ] Implement authentication guards
   - [ ] Add route protection where needed

6. **Update MaterialApp**
   ```dart
   MaterialApp.router(
     routerDelegate: _appRouter.delegate(),
     routeInformationParser: _appRouter.defaultRouteParser(),
     theme: ThemeData(
       useMaterial3: true,
       // Other theme settings
     ),
   )
   ```

7. **Testing & Validation**
   - [ ] Test all navigation flows
   - [ ] Verify route animations with Material 3
   - [ ] Test deep linking
   - [ ] Validate route guards

## Migration Checklist

### Phase 1: Setup
- [ ] Add dependencies
- [ ] Create initial route configuration
- [ ] Generate route code

### Phase 2: Implementation
- [ ] Update MaterialApp
- [ ] Convert existing navigation
- [ ] Add route guards
- [ ] Test basic navigation

### Phase 3: Advanced Features
- [ ] Implement deep linking
- [ ] Add path parameters
- [ ] Configure nested navigation
- [ ] Add route transitions

### Phase 4: Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Deep link tests
- [ ] Performance testing

## References
- [AutoRoute Documentation](https://pub.dev/packages/auto_route)
- [Material 3 Navigation](https://m3.material.io/foundations/interaction/states/overview)
- [Flutter Navigation 2.0](https://docs.flutter.dev/development/ui/navigation)