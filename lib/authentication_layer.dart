library authentication_layer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kotlin_flavor/scope_functions.dart';
import 'package:application_events/events.dart';
import 'package:inject/inject.dart';
import 'package:event_bus/event_bus.dart';

typedef IsUserAuthenticatedFunction = Future<bool> Function();
typedef OnErrorFunction = void Function();
typedef BuildContextConsumer = void Function(BuildContext context);


class LoginSuccessEvent extends ApplicationEvent {
  LoginSuccessEvent() : super(message: 'login success');
}

class AuthenticationLayer extends StatefulWidget {
  final IsUserAuthenticatedFunction isUserAuthenticated;
  final Widget loginView;
  final Widget homeView;
  final OnErrorFunction? onError;
  final void Function()? onStartup;
  final BuildContextConsumer? onLogin;

  AuthenticationLayer(
      {Key? key,
      required this.isUserAuthenticated,
      required this.loginView,
      required this.homeView,
      this.onError,
      this.onStartup,
      this.onLogin})
      : super(key: key) {
    onStartup?.call();
  }

  @override
  _AuthenticationLayerState createState() => _AuthenticationLayerState();

}

class _AuthenticationLayerState extends State<AuthenticationLayer> {
  final events = Inject().get<EventBus>();

  @override
  void didChangeDependencies() {
    _attachToEvents(context);
  }

  void _attachToEvents(BuildContext context) {
    events.on<LoginSuccessEvent>().listen((event) {
      setState(() {
        print('update AuthenticationLayer state');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print('render AuthenticationLayer');
    return FutureBuilder<bool>(
      future: widget.isUserAuthenticated(),
      builder: _buildWidgetDependingOfAuthentication,
    );
  }

  Widget _buildEmptyWidgetInCaseOfError() => const Text('').also((self) {
    widget.onError?.call();
  });

  Widget _buildHomeViewIfAuthenticatedElseLoginView(BuildContext context,
      {required bool authenticated}) {
    if (!authenticated) return widget.loginView;
    widget.onLogin?.call(context);
    return widget.homeView;
  }

  Widget _buildCenteredCircularProgressIndicator() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildWidgetDependingOfAuthentication(
      BuildContext context, AsyncSnapshot<bool> snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.waiting:
        {
          return _buildCenteredCircularProgressIndicator();
        }
        break;
      case ConnectionState.done:
        {
          return snapshot.hasData
              ? _buildHomeViewIfAuthenticatedElseLoginView(context,
              authenticated: snapshot.data!)
              : _buildEmptyWidgetInCaseOfError();
        }
        break;
      default:
        {
          return _buildEmptyWidgetInCaseOfError();
        }
        break;
    }
  }
}
