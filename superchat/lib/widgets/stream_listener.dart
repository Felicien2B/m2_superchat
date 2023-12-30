import 'dart:async';

import 'package:flutter/material.dart';

/// A widget that listens to a [Stream] and calls a listener function when
/// new data is available.
class StreamListener<T> extends StatefulWidget {
  const StreamListener({
    super.key,
    required this.stream,
    required this.child,
    required this.listener,
  });

  final Stream<T> stream;
  final Widget child;
  final void Function(T) listener;

  @override
  State<StreamListener> createState() => _StreamListenerState<T>();
}

class _StreamListenerState<T> extends State<StreamListener<T>> {
  late StreamSubscription<T> _subscription;

  void _subscribe() {
    _subscription = widget.stream.listen(_onData);
  }

  @override
  void initState() {
    _subscribe();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant StreamListener<T> oldWidget) {
    if (widget.stream != oldWidget.stream) {
      _subscription.cancel();
      _subscribe();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onData(T data) {
    widget.listener(data);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
