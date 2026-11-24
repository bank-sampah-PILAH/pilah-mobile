import 'package:flutter/material.dart';

class RoleSwitchObserver extends StatelessWidget {
  const RoleSwitchObserver({super.key, required this.child,
    required this.navigate, this.onError});
  final Widget child;
  final void Function(String location) navigate;
  final void Function(String message)? onError;

  @override
  Widget build(BuildContext context) => child;
}
