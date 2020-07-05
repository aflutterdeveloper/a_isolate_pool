import 'dart:async';

typedef ARunnable<T, R> = FutureOr<R> Function(T param);
typedef AVoidRunnable = Future<void> Function();
typedef AThreadLogger = void Function(
    LOG_LEVEL level, String tag, String message);

enum LOG_LEVEL {
  DEBUG,
  INFO,
  WARN,
  ERROR,
}