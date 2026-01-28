---
name: rearch
description: ReArch state management best practices. Use when implementing capsules, state management, side effects, or Flutter widget integration with ReArch.
argument-hint: [topic]
---

# ReArch Best Practices

ReArch is a declarative approach to application architecture addressing state management, incremental computation, and component-based software engineering.

## Core Concepts

### Capsules

Capsules are encapsulated pieces of data defined as functions consuming a `CapsuleHandle`:

```dart
int countCapsule(CapsuleHandle use) => 0;

(int, void Function(int)) countManagerCapsule(CapsuleHandle use) {
  final (count, setCount) = use.state(0);
  return (count, setCount);
}
```

### CapsuleHandle

The handle provides access to:
- Other capsules via `use(someCapsule)`
- Side effects via `use.state()`, `use.memo()`, `use.effect()`, etc.

### Flutter Setup

Wrap your app with `RearchBootstrapper`:

```dart
void main() {
  runApp(RearchBootstrapper(
    child: MaterialApp(...),
  ));
}
```

---

## Capsule Organization

### Directory Structure

```
lib/
├── core/
│   ├── capsules/           # App-wide infrastructure (config, logging, network)
│   ├── network/services/   # Network service capsules
│   └── services/           # Core service capsules
└── features/
    └── <feature>/
        ├── data/capsules/        # Repository capsules
        ├── domain/use_cases/capsules/  # Use case capsules
        └── presentation/capsules/      # State capsules
```

### Naming Convention

- Capsule functions MUST end with `Capsule`: `authStateCapsule`, `loadTimelineUseCaseCapsule`
- Match non-capsule counterparts where applicable
- File names SHOULD match: `auth_state_capsule.dart`

---

## State Management Patterns

### Simple State (Tuple Pattern)

```dart
(AuthState, void Function(AuthState)) authStateCapsule(CapsuleHandle use) =>
    use.state(AuthState.initial());
```

### State with Manager Class

For complex logic, combine state with a manager class:

```dart
CreatePostStateManager createPostStateCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(CreatePostState.initial());
  final submitPostUseCase = use(submitPostUseCaseCapsule);

  return CreatePostStateManager(
    state: state,
    setState: setState,
    submitPostUseCase: submitPostUseCase,
  );
}

class CreatePostStateManager {
  final CreatePostState state;
  final void Function(CreatePostState) _setState;
  final SubmitPostUseCase _submitPostUseCase;

  CreatePostStateManager({
    required this.state,
    required void Function(CreatePostState) setState,
    required SubmitPostUseCase submitPostUseCase,
  })  : _setState = setState,
        _submitPostUseCase = submitPostUseCase;

  void updateText(String text) {
    _setState(state.copyWith(text: text));
  }

  Future<void> submit() async {
    _setState(state.copyWith(isLoading: true));
    final result = await _submitPostUseCase.execute(...);
    _setState(state.copyWith(isLoading: false));
  }
}
```

### Keyed State (Per-Item State)

For managing multiple instances (e.g., per-user profiles):

```dart
(
  UserProfileState Function(String uuid) getState,
  void Function(String uuid, UserProfileState state) setState,
)
userProfileStateCapsule(CapsuleHandle use) {
  final (stateMap, setStateMap) = use.state<Map<String, UserProfileState>>({});

  UserProfileState getState(String uuid) {
    return stateMap[uuid] ?? const UserProfileInitial();
  }

  void setState(String uuid, UserProfileState state) {
    setStateMap({...stateMap, uuid: state});
  }

  return (getState, setState);
}
```

### Immutable State Classes

MUST use immutable state with `copyWith`:

```dart
class AuthState {
  final bool isAuthenticated;
  final User? currentUser;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.currentUser,
    this.isLoading = false,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    bool? isAuthenticated,
    User? currentUser,
    bool? isLoading,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        currentUser: currentUser ?? this.currentUser,
        isLoading: isLoading ?? this.isLoading,
      );
}
```

---

## Side Effects

### Memoization

Use `use.memo()` for expensive object creation:

```dart
AppInfoService appInfoServiceCapsule(CapsuleHandle use) {
  return use.memo(() => AppInfoService()..initialize(), []);
}
```

### Effects with Cleanup

MUST return cleanup function for resources:

```dart
GrpcChannelManager grpcChannelManagerCapsule(CapsuleHandle use) {
  final manager = use.memo(() => GrpcChannelManager(...));

  use.effect(() {
    return () async {
      await manager.shutdown();  // Cleanup callback
    };
  });

  return manager;
}
```

### Stream Subscriptions

```dart
(MaintenanceState, void Function(MaintenanceState)) maintenanceStateCapsule(
  CapsuleHandle use,
) {
  final state = use.state(const MaintenanceState());
  final notifier = use(maintenanceNotifierCapsule);

  use.effect(() {
    final subscription = notifier.stream.listen((message) {
      state.$2(MaintenanceState(message: message));
    });
    return subscription.cancel;  // MUST cleanup
  }, [notifier]);

  return state;
}
```

### TextEditingController Cleanup

```dart
ProfileFormControllers profileFormControllerCapsule(CapsuleHandle use) {
  final nameController = use.memo(() => TextEditingController());
  final emailController = use.memo(() => TextEditingController());

  use.effect(() {
    return () {
      nameController.dispose();
      emailController.dispose();
    };
  }, []);

  return ProfileFormControllers(
    name: nameController,
    email: emailController,
  );
}
```

---

## Dependency Injection

### Service Capsules

```dart
AuthGrpcService authGrpcServiceCapsule(CapsuleHandle use) {
  final channelManager = use(grpcChannelManagerCapsule);
  final appInfo = use(appInfoServiceCapsule);
  final loggingInterceptor = use(grpcLoggingInterceptorCapsule);

  return AuthGrpcService(
    channelManager,
    appInfo,
    interceptors: [loggingInterceptor],
  );
}
```

### Repository Capsules

```dart
TimelineRepository timelineRepositoryCapsule(CapsuleHandle use) {
  final remoteDataSource = use(timelineRemoteDataSourceCapsule);
  final uploadService = use(imageUploadServiceCapsule);
  final authRepository = use(authRepositorySyncCapsule);
  final logger = use(loggerServiceCapsule);

  return TimelineRepositoryImpl(
    remoteDataSource: remoteDataSource,
    uploadService: uploadService,
    authRepository: authRepository,
    logger: logger,
  );
}
```

### Use Case Capsules

```dart
LoadTimelineUseCase loadTimelineUseCaseCapsule(CapsuleHandle use) {
  final repository = use(timelineRepositoryCapsule);
  final logger = createTaggedLogger(use, 'LoadTimelineUseCase');
  return LoadTimelineUseCase(repository, logger);
}
```

---

## Flutter Widget Integration

### RearchConsumer

```dart
class TimelinePage extends RearchConsumer {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final manager = use(timelineStateCapsule);

    // Initialization effect
    use.effect(() {
      if (!manager.state.hasInitialized) {
        manager.loadInitialPosts();
      }
      return null;
    }, []);

    return Scaffold(
      body: TimelineContent(manager: manager),
    );
  }
}
```

### Effect-Driven Navigation

```dart
@override
Widget build(BuildContext context, WidgetHandle use) {
  final (authState, _) = use(authStateCapsule);

  use.effect(() {
    if (authState.hasCheckedAutoLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (authState.isAuthenticated) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        }
      });
    }
    return null;
  }, [authState.hasCheckedAutoLogin, authState.isAuthenticated]);

  return const Scaffold(body: Center(child: CircularProgressIndicator()));
}
```

---

## AsyncValue Pattern

```dart
AsyncValue<AuthRepository> authRepositoryCapsule(CapsuleHandle use) {
  final remoteDataSourceAsync = use(authRemoteDataSourceAsyncCapsule);

  return switch (remoteDataSourceAsync) {
    AsyncData(:final data) => AsyncData(AuthRepositoryImpl(data)),
    AsyncLoading() => const AsyncLoading(None()),
    AsyncError(:final error, :final stackTrace) =>
        AsyncError(error, stackTrace, None()),
  };
}
```

---

## Rules

### MUST Follow

- MUST use immutable state classes with `copyWith`
- MUST return cleanup function in effects when managing resources
- MUST use `use.memo()` for expensive object creation
- MUST end capsule function names with `Capsule`
- MUST dispose TextEditingControllers in effect cleanup
- MUST cancel stream subscriptions in effect cleanup

### SHOULD Follow

- SHOULD use Manager classes for complex state logic
- SHOULD use tagged loggers for debugging
- SHOULD organize capsules by layer (data/domain/presentation)
- SHOULD use keyed state pattern for per-item state
- SHOULD use tuple returns for state + setter pairs

### NEVER Do

- NEVER mutate state directly; always use setState
- NEVER create expensive objects without memoization
- NEVER forget cleanup callbacks in effects
- NEVER use effects without dependency arrays when dependencies exist

---

## Dependency Order

Build capsules in this order (bottom to top):

1. **Config/Infrastructure** - AppConfig, Logger
2. **Network Services** - gRPC services, HTTP clients
3. **Repositories** - Data access layer
4. **Use Cases** - Business logic
5. **State Capsules** - UI state management
6. **Widgets** - RearchConsumer widgets

---

## References

- Documentation: https://rearch.gsconrad.com
- Package: https://pub.dev/packages/rearch
- Flutter Package: https://pub.dev/packages/flutter_rearch
