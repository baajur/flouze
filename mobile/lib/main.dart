import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:sentry/sentry.dart';

import 'package:flouze/localization.dart';
import 'package:flouze/pages/account_clone.dart';
import 'package:flouze/pages/account_list.dart';
import 'package:flouze/utils/applinks.dart' as applinks;
import 'package:flouze/utils/build_info.dart';
import 'package:flouze/utils/services.dart';

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true); // Only evaluated in debug mode
  return inDebugMode;
}

Future<SentryClient> _initSentry() async {
  if (isInDebugMode) {
    return null;
  }

  try {
    Map<String, dynamic> eventData = {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'build_info': await getBuildInfo(),
    };

    return SentryClient(
      dsn: (await rootBundle.loadString('assets/sentry_dsn.txt')).trim(),
      environmentAttributes: Event(extra: eventData),
    );
  } catch (e) {
    print('Error while loading Sentry configuration: $e');
    // Probably no sentry DSN found
    return null;
  }
}

Future<void> _reportError(SentryClient client, dynamic error, dynamic stackTrace) async {
  print('Caught error: $error');

  if (isInDebugMode || client == null) {
    print(stackTrace);
    print('In dev mode or Sentry not configured. Not sending report to Sentry.io.');
    return;
  }

  print('Reporting to Sentry.io...');

  final SentryResponse response = await client.captureException(
    exception: error,
    stackTrace: stackTrace,
  );

  if (response.isSuccessful) {
    print('Success! Event ID: ${response.eventId}');
  } else {
    print('Failed to report to Sentry.io: ${response.error}');
  }
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<applinks.LinkAction> _linkActions;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _linkActions = applinks.linkActions().listen((action) {
      final navigator = _navigatorKey.currentState;
      if (mounted && navigator != null && action is applinks.LinkActionClone) {
        navigator.push(MaterialPageRoute(builder: (context) =>
          new AccountClonePage(accountUuid: action.accountUuid)
        ));
      }
    });
  }

  @override
  void dispose() {
    _linkActions?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      closeRepository();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flouze!',
      theme: new ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AccountListPage(),
      navigatorKey: _navigatorKey,
      localizationsDelegates: [
        const FlouzeLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('fr'),
      ],
    );
  }
}

Future<void> main() async {
  var sentryClient = await _initSentry();

  FlutterError.onError = (FlutterErrorDetails details) async {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  runZoned<Future<void>>(() async {
    runApp(new MyApp());
  }, onError: (error, stackTrace) async {
    await _reportError(sentryClient, error, stackTrace);
  });
}
