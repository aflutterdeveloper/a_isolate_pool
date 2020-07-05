//Copyright (C) 2020 adeveloper.tech
//
//Permission is hereby granted, free of charge, to any person obtaining
//a copy of this software and associated documentation files (the
//"Software"), to deal in the Software without restriction, including
//without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to
//permit persons to whom the Software is furnished to do so, subject to
//the following conditions:
//
//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:a_thread_pool/exception/a_exception_factory.dart';
import 'package:dio/dio.dart';

import 'exception/a_exception.dart';
import 'exception/error_format.dart';

typedef ARunnable<T, R> = FutureOr<R> Function(T param);
typedef AVoidRunnable = Future<void> Function();
typedef AThreadLogger = void Function(
    LOG_LEVEL level, String tag, String message);

class ThreadService {
  final String _tag;
  _IsolateClient _client;

  static AThreadLogger _aIsolateLogger;

  static set logger(AThreadLogger logger) {
    _aIsolateLogger = logger;
  }

  static AThreadLogger get logger {
    return ThreadService._threadServiceLogger;
  }

  ///构建一个线程服务
  ///@param String tag 线程标识
  ThreadService.build([String tag, AExceptionFactory factory])
      : _tag = tag ?? _randomTag() {
    logger(LOG_LEVEL.INFO, "IsolatePool", "building isolate $_tag");
    _client = _IsolateClient(_tag, factory);
  }

  ///启动线程服务
  Future start() async {
    if (!isRunning) {
      return _client.connect();
    }
  }

  ///停止线程服务
  Future stop() async {
    if (isRunning) {
      _client.close();
    }
  }

  ///在线程中执行runnable
  ///@param runnable 要执行的函数实体
  ///The function must be a top-level function or a static method that can be
  ///called with a single argument,that is, a compile-time constant function
  ///value which accepts at least one positional parameter and has at most one
  /// required positional parameter.
  FutureOr<R> run<T, R>(ARunnable<T, R> runnable, T param) {
    return delay(null, runnable, param);
  }

  ///在线程中延迟执行runnable
  ///@param runnable 要执行的函数实体
  ///The function must be a top-level function or a static method that can be
  ///called with a single argument,that is, a compile-time constant function
  ///value which accepts at least one positional parameter and has at most one
  /// required positional parameter.
  FutureOr<R> delay<T, R>(Duration duration, ARunnable<T, R> runnable,
      T param) {
    return _client.send(duration, runnable, param);
  }

  ///线程是否在运行
  ///@return true 正在运行
  bool get isRunning => _client._working;

  static String _randomTag() {
    return DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
  }

  static void _threadServiceLogger(LOG_LEVEL level, String tag,
      String message) {
    if (null != _IsolateServer.loggerPort) {
      _IsolateServer.loggerPort.send(_ServiceLog(level, tag, message));
    } else {
      if (null != _aIsolateLogger) {
        _aIsolateLogger(level, tag, message);
      } else {
        print("$level $tag $message");
      }
    }
  }
}

class _IsolateClient {
  Isolate _nativeThread;
  final String _tag;
  final AExceptionFactory _exceptionFactory;

  final Map<int, Completer> _responseMap = Map<int, Completer>();
  int _reqSeqSeed = 0;

  final ReceivePort _receivePort = ReceivePort();
  final ReceivePort _errorPort = ReceivePort();
  SendPort _serverPort;
  bool _working = false;

  _IsolateClient(this._tag, this._exceptionFactory);

  Future connect() async {
    _working = true;

    _errorPort.listen((errorData) {
      assert(errorData is List<dynamic>);
      assert(errorData.length == 2);
      final Exception exception = Exception(errorData[0]);
      final StackTrace stack = StackTrace.fromString(errorData[1]);
      Zone.current.handleUncaughtError(exception, stack);
    });

    Completer initCompleter = Completer();
    _receivePort.listen(
            (dynamic response) {
          if (response is _ServiceResponse) {
            final completer = _responseMap.remove(response.seq);
            if (null != completer) {
              completer.complete(response.response);
            }
          } else if (response is _ServiceError) {
            final completer = _responseMap.remove(response.seq);
            if (null != completer) {
              completer.completeError(response.error);
            }
          } else if (response is _ServiceInitResponse) {
            _serverPort = response.serverPort;
            initCompleter.complete();
          } else if (response is _ServiceLog) {
            if (!isThread()) {
              ThreadService._threadServiceLogger(
                  LOG_LEVEL.INFO, response.tag, response.message);
            }
          }
        },
        onError: (error) {
          ThreadService._threadServiceLogger(
              LOG_LEVEL.INFO, _tag, "unknown error ${error.toString()}");
        },
        cancelOnError: true,
        onDone: () {
          _working = false;
          ThreadService._threadServiceLogger(
              LOG_LEVEL.INFO, _tag, "thread client closed");
        });

    final initParam = _ServiceInit(
        _receivePort.sendPort, _tag, _exceptionFactory);
    _nativeThread = await Isolate.spawn(_nativeService, initParam,
        onExit: _receivePort.sendPort,
        errorsAreFatal: true,
        onError: _errorPort.sendPort);

    return initCompleter.future;
  }

  Future<R> send<T, R>(Duration duration, ARunnable<T, R> runnable, T param) {
    Completer<R> completer = Completer<R>();
    int runnableIndex = _seq();
    _responseMap[runnableIndex] = completer;
    _serverPort.send(
        _ServiceRequest<T, R>(duration, runnableIndex, runnable, param));
    return completer.future;
  }

  void setServerPort(SendPort serverPort) {
    this._serverPort = serverPort;
  }

  Future close() async {
    if (_working) {
      _serverPort.send(_ServiceDestroy());
      _nativeThread.kill();
      _receivePort.close();
      _errorPort.close();
    }
  }

  int _seq() {
    return ++_reqSeqSeed;
  }
}

class _IsolateServer {
  final String _tag;
  final AExceptionFactory _default = AExceptionFactory();
  final AExceptionFactory _exceptionFactory;
  final ReceivePort _receivePort = ReceivePort();
  SendPort _clientPort;
  static SendPort loggerPort;

  _IsolateServer(this._clientPort, this._tag, this._exceptionFactory) {
    loggerPort = _clientPort;

    _receivePort.listen(
            (request) async {
          if (request is _ServiceRequest) {
            try {
              if (request.delay != null && request.delay.inMilliseconds > 0) {
                await Future.delayed(request.delay);
              }

              final result = await request.invoke();
              _clientPort.send(_ServiceResponse(request.seq, result));
            } catch (err, stack) {
              AExceptionFactory _factory = _exceptionFactory ?? _default;
              final exception = _factory.build(err, stack);

              ThreadService._threadServiceLogger(LOG_LEVEL.ERROR,
                  "_ThreadServer", exception.error);

              try {
                _clientPort
                    .send(_ServiceError(request.seq, exception));
              } catch (ignore, ignoreStack) {
                _clientPort.send(_ServiceError(
                    request.seq, _factory.defaultBuilder.build(err, stack)));
              }
            }
          } else if (request is _ServiceDestroy) {
            ThreadService._threadServiceLogger(
                LOG_LEVEL.INFO, _tag, "thread server destroyed");
            _receivePort.close();
          }
        },
        onError: (error) {
          ThreadService._threadServiceLogger(
              LOG_LEVEL.ERROR, _tag, "unknown error ${error.toString()}");
        },
        cancelOnError: true,
        onDone: () {
          loggerPort = null;
          ThreadService._threadServiceLogger(
              LOG_LEVEL.INFO, _tag, "thread server closed");
        });

    final response = _ServiceInitResponse(_receivePort.sendPort);
    _clientPort.send(response);
  }
}

void _nativeService(_ServiceInit initParam) {
  _IsolateServer(
      initParam.clientPort, initParam.tag, initParam._exceptionFactory);
}

bool isThread() {
  return _IsolateServer.loggerPort != null;
}

class _ServiceInit {
  final SendPort clientPort;
  final String tag;
  final AExceptionFactory _exceptionFactory;

  _ServiceInit(this.clientPort, this.tag, this._exceptionFactory);
}

class _ServiceDestroy {
  _ServiceDestroy();
}

class _ServiceInitResponse {
  final SendPort serverPort;

  _ServiceInitResponse(this.serverPort);
}

class _ServiceRequest<T, R> {
  final int seq;
  final T param;
  final Duration delay;
  final ARunnable<T, R> runnable;

  _ServiceRequest(this.delay, this.seq, this.runnable, this.param);

  FutureOr<R> invoke() async {
    return await runnable(param);
  }
}

class _ServiceResponse<T> {
  final int seq;
  final T response;

  _ServiceResponse(this.seq, this.response);
}

class _ServiceError {
  _ServiceError(this.seq, this.error);

  final int seq;
  final dynamic error;
}

enum LOG_LEVEL {
  DEBUG,
  INFO,
  WARN,
  ERROR,
}

class _ServiceLog {
  _ServiceLog(this.level, this.tag, this.message);

  LOG_LEVEL level;
  String tag;
  String message;
}
