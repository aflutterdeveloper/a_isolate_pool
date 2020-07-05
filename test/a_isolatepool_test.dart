import 'dart:isolate';

import 'package:a_thread_pool/a_thread_pool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test io thread', () async {
    ThreadPool.logger = testLogger;
    expect(await ThreadPool.io.run(testIsolateRun, "params for testIsolateRun"),
        true);
    expect(
        await ThreadPool.io
            .run(testIsolateRun, _AnyParam(true, 200, 200.0, "stringParam")),
        true);
    //expect(() => IsolatePool.io.addOne(null), throwsNoSuchMethodError);
  });
}

bool testIsolateRun(Object any) {
  ThreadPool.logger(LOG_LEVEL.INFO, "testIsolateRun",
      "working on thread ${Isolate.current.toString()}, param:$any");
  return true;
}

Future<void> testLogger(LOG_LEVEL level, String tag, String message) async {
  print("testLogger $level $tag $message");
}

class _AnyParam {
  final bool boolParam;
  final int intParam;
  final double doubleParam;
  final String stringParam;

  _AnyParam(this.boolParam, this.intParam, this.doubleParam, this.stringParam);

  @override
  String toString() {
    return "bool:$boolParam, int:$intParam, double:$doubleParam, string:$stringParam";
  }
}
