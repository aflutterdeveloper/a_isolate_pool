import 'dart:isolate';

import 'package:a_thread_pool/a_thread_pool.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreadPool Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Thread Pool Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    ThreadPool.logger = (level, tag, message){
      print("level:$level $tag $message");
    };

    _runDemo();

    super.initState();
  }

  void _runDemo() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(child: Text("Click Run Isolate Thread Pool Demo"),onPressed: (){
              _runDemo();
            },),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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

