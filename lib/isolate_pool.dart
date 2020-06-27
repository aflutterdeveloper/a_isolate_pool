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

import 'isolate_service.dart';

class IsolatePool {
  static final IsolatePool io = IsolatePool.build(
      max(3, (Platform.numberOfProcessors * 0.6).floor()), "io_thread_pool");

  final String _tag;
  final int _threadCount;
  final Map<int, IsolateService> _threadMap = Map<int, IsolateService>();
  int _lastRunIndex = -1;

  static set logger(AIsolateLogger logger) {
    IsolateService.logger = logger;
  }

  static AIsolateLogger get logger {
    return IsolateService.logger;
  }


  /// 构建一个隔离线程池
  IsolatePool.build(int threadCount, [String tag])
      : _threadCount = threadCount ?? 1,
        _tag = tag ?? _randomTag();

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
      return (await _getNextThread())
          .run(runnable, param);
    } else {
      logger(LOG_LEVEL.ERROR, "IsolatePool", "run thread pool is empty");
    }
    return null;
  }

  /// 停止隔离线程池
  void stop() {
    if (_threadMap != null) {
      _threadMap.values.forEach((IsolateService thread) {
        thread.stop();
      });
      _threadMap.clear();
    }
  }

  Future<IsolateService> _getNextThread() async {
    if (_lastRunIndex < 0) {
      _lastRunIndex = 0;
    } else {
      _lastRunIndex = (++_lastRunIndex) % _threadCount;
    }

    IsolateService thread = _threadMap[_lastRunIndex];
    if (null == thread || !thread.isRunning) {
      final tag = "${_tag}_$_lastRunIndex";
      thread = IsolateService.build(tag);
      await thread.start();
      _threadMap[_lastRunIndex] = thread;
    }
    return thread;
  }

  static String _randomTag() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
