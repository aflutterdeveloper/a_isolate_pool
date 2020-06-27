# isolate pool
Help developers use Isolate more friendly under the flutter framework to activate the multi-core performance of the device.

## Getting Started
### example:
```
//define a top-level function
bool testIsolateRun(Object any) {
  IsolatePool.logger(LOG_LEVEL.INFO, "testIsolateRun", "working on thread ${Isolate.current.toString()}, param:$any");
  return true;
}

//Run testIsolateRun in the isolated thread pool
IsolatePool.io.run(testIsolateRun, "params for testIsolateRun");
//Run testIsolateRun in the isolated thread pool with custom params
IsolatePool.io.run(testIsolateRun, _AnyParam(true, 200, 200.0,"stringParam"))
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