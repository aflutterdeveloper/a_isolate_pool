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

import 'dart:io';
import 'dart:math';

import 'package:a_thread_pool/exception/a_exception_factory.dart';

import 'exception/dio_exception_builder.dart';
import 'thread_service.dart';

class ThreadPool {
  static final ThreadPool io = ThreadPool.build(
      max(3, (Platform.numberOfProcessors * 0.6).floor()), "io_thread_pool");

  final String _tag;
  final int _threadCount;
  final Map<int, ThreadService> _threadMap = Map<int, ThreadService>();
  int _lastRunIndex = -1;

  static AExceptionFactory _exceptionFactory = AExceptionFactory();

  static set logger(AThreadLogger logger) {
    ThreadService.logger = logger;
  }

  static AThreadLogger get logger {
    return ThreadService.logger;
  }

  static addExceptionBuilder(AExceptionBuilder builder) {
    _exceptionFactory.addBuilder(builder);
  }

  static removeExceptionBuilder(AExceptionBuilder builder) {
    _exceptionFactory.removeBuilder(builder);
  }

  /// 构建一个隔离线程池
  ThreadPool.build(int threadCount, [String tag])
      : _threadCount = threadCount ?? 1,
        _tag = tag ?? _randomTag(){
    _exceptionFactory.addBuilder(DioExceptionBuilder());
  }

  ///在隔离线程中执runnable
  ///@param runnable 要执行的函数实体
  ///@param param  透传给runnable的参数
  ///The runnable must be a top-level function or a static method that can be
  ///called with a single argument,that is, a compile-time constant function
  ///value which accepts at least one positional parameter and has at most one
  /// required positional parameter.
  Future<R> run<T, R>(ARunnable<T, R> runnable, T param,
      {String debugLabel}) async {
    if (_threadCount > 0) {
      return (await _getNextThread()).run(runnable, param);
    } else {
      logger(LOG_LEVEL.ERROR, "IsolatePool", "run thread pool is empty");
    }
    return null;
  }

  /// 停止隔离线程池
  void stop() {
    if (_threadMap != null) {
      _threadMap.values.forEach((ThreadService thread) {
        thread.stop();
      });
      _threadMap.clear();
    }
  }

  Future<ThreadService> _getNextThread() async {
    if (_lastRunIndex < 0) {
      _lastRunIndex = 0;
    } else {
      _lastRunIndex = (++_lastRunIndex) % _threadCount;
    }

    ThreadService thread = _threadMap[_lastRunIndex];
    if (null == thread || !thread.isRunning) {
      final tag = "${_tag}_$_lastRunIndex";
      thread = ThreadService.build(tag);
      await thread.start();
      _threadMap[_lastRunIndex] = thread;
    }
    return thread;
  }

  static String _randomTag() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
