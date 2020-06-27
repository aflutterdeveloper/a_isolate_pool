# thread pool
Help developers use Isolate more friendly under the flutter framework to activate the multi-core performance of the device.

## Getting Started
### example:
```
//define a top-level function
bool testThreadRun(Object any) {
  ThreadPool.logger(LOG_LEVEL.INFO, "testThreadRun", "working on thread ${Isolate.current.toString()}, param:$any");
  return true;
}

//Run testThreadRun in the isolated thread pool
ThreadPool.io.run(testThreadRun, "params for testThreadRun");
//Run testIsolateRun in the isolated thread pool with custom params
ThreadPool.io.run(testThreadRun, _AnyParam(true, 200, 200.0,"stringParam"))
        .catchError((error){
        //catch exception from isolate thread
});


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

```