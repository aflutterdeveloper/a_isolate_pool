import 'dart:isolate';

import 'package:aisolatepool/isolate_pool.dart';
import 'package:aisolatepool/isolate_service.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
    IsolatePool.logger = (level, tag, message){
      print("level:$level $tag $message");
    };

    //Run testIsolateRun in the isolated thread pool
    IsolatePool.io.run(testIsolateRun, "params for testIsolateRun");
    //Run testIsolateRun in the isolated thread pool with custom params
    IsolatePool.io.run(testStaticIsolateRun, _AnyParam(true, 200, 200.0,"stringParam"))
        .catchError((error){
    //catch exception from isolate thread
    });

    super.initState();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
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
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  //define a static function
  static bool testStaticIsolateRun(Object any) {
    IsolatePool.logger(LOG_LEVEL.INFO, "testIsolateRun", "working on thread ${Isolate.current.toString()}, param:$any");
    return true;
  }


}


//define a top-level function
bool testIsolateRun(Object any) {
  IsolatePool.logger(LOG_LEVEL.INFO, "testIsolateRun", "working on thread ${Isolate.current.toString()}, param:$any");
  return true;
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

