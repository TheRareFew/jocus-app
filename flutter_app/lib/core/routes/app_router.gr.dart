// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CameraScreen]
class CameraRoute extends PageRouteInfo<CameraRouteArgs> {
  CameraRoute({
    Key? key,
    ComedyStructure? structure,
    List<PageRouteInfo>? children,
  }) : super(
         CameraRoute.name,
         args: CameraRouteArgs(key: key, structure: structure),
         initialChildren: children,
       );

  static const String name = 'CameraRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CameraRouteArgs>(
        orElse: () => const CameraRouteArgs(),
      );
      return CameraScreen(key: args.key, structure: args.structure);
    },
  );
}

class CameraRouteArgs {
  const CameraRouteArgs({this.key, this.structure});

  final Key? key;

  final ComedyStructure? structure;

  @override
  String toString() {
    return 'CameraRouteArgs{key: $key, structure: $structure}';
  }
}

/// generated route for
/// [DashboardScreen]
class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardScreen();
    },
  );
}

/// generated route for
/// [EditComedyStructureScreen]
class EditComedyStructureRoute
    extends PageRouteInfo<EditComedyStructureRouteArgs> {
  EditComedyStructureRoute({
    Key? key,
    required ComedyStructure structure,
    required String userId,
    VoidCallback? onSave,
    List<PageRouteInfo>? children,
  }) : super(
         EditComedyStructureRoute.name,
         args: EditComedyStructureRouteArgs(
           key: key,
           structure: structure,
           userId: userId,
           onSave: onSave,
         ),
         initialChildren: children,
       );

  static const String name = 'EditComedyStructureRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditComedyStructureRouteArgs>();
      return EditComedyStructureScreen(
        key: args.key,
        structure: args.structure,
        userId: args.userId,
        onSave: args.onSave,
      );
    },
  );
}

class EditComedyStructureRouteArgs {
  const EditComedyStructureRouteArgs({
    this.key,
    required this.structure,
    required this.userId,
    this.onSave,
  });

  final Key? key;

  final ComedyStructure structure;

  final String userId;

  final VoidCallback? onSave;

  @override
  String toString() {
    return 'EditComedyStructureRouteArgs{key: $key, structure: $structure, userId: $userId, onSave: $onSave}';
  }
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [MyComedyStructuresScreen]
class MyComedyStructuresRoute
    extends PageRouteInfo<MyComedyStructuresRouteArgs> {
  MyComedyStructuresRoute({
    Key? key,
    bool selectionMode = false,
    List<PageRouteInfo>? children,
  }) : super(
         MyComedyStructuresRoute.name,
         args: MyComedyStructuresRouteArgs(
           key: key,
           selectionMode: selectionMode,
         ),
         initialChildren: children,
       );

  static const String name = 'MyComedyStructuresRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MyComedyStructuresRouteArgs>(
        orElse: () => const MyComedyStructuresRouteArgs(),
      );
      return MyComedyStructuresScreen(
        key: args.key,
        selectionMode: args.selectionMode,
      );
    },
  );
}

class MyComedyStructuresRouteArgs {
  const MyComedyStructuresRouteArgs({this.key, this.selectionMode = false});

  final Key? key;

  final bool selectionMode;

  @override
  String toString() {
    return 'MyComedyStructuresRouteArgs{key: $key, selectionMode: $selectionMode}';
  }
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
    : super(OnboardingRoute.name, initialChildren: children);

  static const String name = 'OnboardingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OnboardingScreen();
    },
  );
}

/// generated route for
/// [SignupScreen]
class SignupRoute extends PageRouteInfo<void> {
  const SignupRoute({List<PageRouteInfo>? children})
    : super(SignupRoute.name, initialChildren: children);

  static const String name = 'SignupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignupScreen();
    },
  );
}

/// generated route for
/// [StudioScreen]
class StudioRoute extends PageRouteInfo<void> {
  const StudioRoute({List<PageRouteInfo>? children})
    : super(StudioRoute.name, initialChildren: children);

  static const String name = 'StudioRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StudioScreen();
    },
  );
}

/// generated route for
/// [TrendingFormatsScreen]
class TrendingFormatsRoute extends PageRouteInfo<void> {
  const TrendingFormatsRoute({List<PageRouteInfo>? children})
    : super(TrendingFormatsRoute.name, initialChildren: children);

  static const String name = 'TrendingFormatsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TrendingFormatsScreen();
    },
  );
}
