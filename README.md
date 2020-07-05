# thread pool
Help developers use Isolate more friendly under the flutter framework to activate the multi-core performance of the device.

## Getting Started
### example:
```
//Run testIsolateRun in the isolated thread pool
    ThreadPool.io.run(testThreadRun, "params for testThreadRun");
    //Run testIsolateRun in the isolated thread pool with custom params
    final response = await ThreadPool.io.run(testStaticThreadRun, _AnyParam(true, 200, 200.0,"stringParam", {"kev1":0, "key2":"any type"}, ["fasfa", 1000]))
        .catchError((error){
      //catch exception from isolate thread
    });
    print(response);

    //catch AException from isolate thread
    await ThreadPool.io.run(testExceptionStaticThreadRun, "exception test").catchError((err){
      print("exception from thread:${err.runtimeType}, $err");
    });

    //catch any exception from isolate thread
    await ThreadPool.io.delay(Duration(seconds: 3), testLambdaExceptionStaticThreadRun, "exception test").catchError((err){
      print("exception from thread:${err.runtimeType}, $err");
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

 //define a static function
  static _AnyResponse testStaticThreadRun(Object any) {
    ThreadPool.logger(LOG_LEVEL.INFO, "testIsolateRun", "working on thread ${Isolate.current}, param:$any");
    return _AnyResponse(false, 100, 300.0,"stringResponse", {"kev1Response":0, "key2Response":"any type"}, ["Response:fasfa", 2000]);
  }

  static _AnyResponse testExceptionStaticThreadRun(Object any) {
    ThreadPool.logger(LOG_LEVEL.INFO, "testExceptionStaticThreadRun", "working on thread ${Isolate.current}, param:$any");
    throw MyException("my excption from isolate, param:$any");
  }

  static _AnyResponse testLambdaExceptionStaticThreadRun(Object any) {
    ThreadPool.logger(LOG_LEVEL.INFO, "testLambdaExceptionStaticThreadRun", "working on thread ${Isolate.current}, param:$any");
    throw MyLambdaException("my lambda excption from isolate, param:$any");
  }
}


//define a top-level function
bool testThreadRun(Object any) {
  ThreadPool.logger(LOG_LEVEL.INFO, "testIsolateRun", "working on thread ${Isolate.current.toString()}, param:$any");
  return true;
}


class _AnyParam {
  final bool boolParam;
  final int intParam;
  final double doubleParam;
  final String stringParam;
  final Map<String, dynamic> mapParam;
  final List<dynamic> listParam;

  _AnyParam(this.boolParam, this.intParam, this.doubleParam, this.stringParam, this.mapParam, this.listParam);

  @override
  String toString() {
    return "bool:$boolParam, int:$intParam, double:$doubleParam, string:$stringParam, map:$mapParam, list:$listParam";
  }
}

class _AnyResponse {
  final bool boolParam;
  final int intParam;
  final double doubleParam;
  final String stringParam;
  final Map<String, dynamic> mapParam;
  final List<dynamic> listParam;

  _AnyResponse(this.boolParam, this.intParam, this.doubleParam, this.stringParam, this.mapParam, this.listParam);

  @override
  String toString() {
    return "response from thread, bool:$boolParam, int:$intParam, double:$doubleParam, string:$stringParam, map:$mapParam, list:$listParam";
  }
}

class MyException extends AException{
  MyException(String error) : super(error);
}

class MyLambdaException{
  ARunnable runnable = (param){};
  MyLambdaException(String error);
}

```