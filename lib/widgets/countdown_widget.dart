import 'dart:async';
import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  final DateTime? targetDate;
  final TextStyle? style;

  const CountdownWidget({super.key, this.targetDate, this.style});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    if (widget.targetDate == null) {
      _timeLeft = Duration.zero;
      return;
    }
    setState(() {
      _timeLeft = widget.targetDate!.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetDate == null) return const SizedBox.shrink();

    if (_timeLeft.isNegative) {
      return Text('¡EVENTO EN MARCHA!', style: widget.style?.copyWith(color: Colors.green, fontWeight: FontWeight.bold));
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    String text = '';
    if (days > 0) text += '${days}d ';
    text += '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Text('Faltan $text', style: widget.style);
  }
}
