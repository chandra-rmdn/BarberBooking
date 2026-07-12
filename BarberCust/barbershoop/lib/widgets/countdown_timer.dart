import 'dart:async';
import 'package:flutter/material.dart';

/// Widget countdown yang menghitung mundur dari [expiredAt] hingga sekarang.
///
/// Basis perhitungan selalu `expiredAt - DateTime.now()`, bukan angka
/// yang di-decrement manual, sehingga tetap akurat walau app sempat
/// di-background lalu dibuka lagi.
class CountdownTimer extends StatefulWidget {
  final DateTime expiredAt;
  final VoidCallback? onExpired;
  final TextStyle? textStyle;
  final TextStyle? urgentTextStyle;
  final Duration urgentThreshold;

  const CountdownTimer({
    super.key,
    required this.expiredAt,
    this.onExpired,
    this.textStyle,
    this.urgentTextStyle,
    this.urgentThreshold = const Duration(minutes: 2),
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with WidgetsBindingObserver {
  Timer? _timer;
  late Duration _remaining;
  bool _hasCalledExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = _calculateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kalau expiredAt berubah (misal booking di-reschedule), reset ulang.
    if (oldWidget.expiredAt != widget.expiredAt) {
      _hasCalledExpired = false;
      _tick();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Begitu app kembali aktif, langsung recalculate supaya tidak
    // menunggu tick berikutnya (bisa saja app di-background lama).
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  Duration _calculateRemaining() {
    final diff = widget.expiredAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = _calculateRemaining();
    if (!mounted) return;

    setState(() => _remaining = remaining);

    if (remaining == Duration.zero && !_hasCalledExpired) {
      _hasCalledExpired = true;
      _timer?.cancel();
      widget.onExpired?.call();
    }
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining <= widget.urgentThreshold;
    final defaultStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 16,
          color: isUrgent ? Colors.red : Colors.grey[700],
        ),
        const SizedBox(width: 4),
        Text(
          _remaining == Duration.zero ? 'Waktu habis' : _format(_remaining),
          style: (isUrgent
                  ? (widget.urgentTextStyle ??
                      defaultStyle?.copyWith(color: Colors.red))
                  : (widget.textStyle ?? defaultStyle)) ??
              const TextStyle(),
        ),
      ],
    );
  }
}