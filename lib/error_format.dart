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

import 'dart:convert';

import 'package:stack_trace/stack_trace.dart';

class ErrorFormat {
  ErrorFormat(this.exception, this.stackTrace);

  final dynamic exception;
  final dynamic stackTrace;

  String toJson() {
    final Map<String, dynamic> errorJson = Map<String, dynamic>();
    if (exception != null) {
      errorJson['exception'] = [
        <String, dynamic>{
          'type': '${exception.runtimeType}',
          'value': '$exception',
        }
      ];
    }

    if (stackTrace != null) {
      errorJson['stacktrace'] = <String, dynamic>{
        'frames': _encodeStackTrace(stackTrace),
      };
    }
    try {
      return json.encode(errorJson);
    } catch (e) {
      return "error format failed";
    }
  }

  List<Map<String, dynamic>> _encodeStackTrace(dynamic stackTrace) {
    assert(stackTrace is String || stackTrace is StackTrace);
    final Chain chain = stackTrace is StackTrace
        ? new Chain.forTrace(stackTrace)
        : new Chain.parse(stackTrace);

    final List<Map<String, dynamic>> frames = <Map<String, dynamic>>[];
    for (int t = 0; t < chain.traces.length; t += 1) {
      frames.addAll(chain.traces[t].frames.map(_encodeStackTraceFrame));
      if (t < chain.traces.length - 1) frames.add(_asynchronousGapFrameJson);
    }

    final jsonFrames = frames.reversed.toList();
    return jsonFrames;
  }

  Map<String, dynamic> _encodeStackTraceFrame(Frame frame) {
    final Map<String, dynamic> json = <String, dynamic>{
      'abs_path': _absolutePathForCrashReport(frame),
      'function': frame.member,
      'lineno': frame.line,
      'in_app': !frame.isCore,
    };

    if (frame.uri.pathSegments.isNotEmpty)
      json['filename'] = frame.uri.pathSegments.last;

    return json;
  }

  final Map<String, dynamic> _asynchronousGapFrameJson =
      const <String, dynamic>{
    'abs_path': '<asynchronous suspension>',
  };

  String _absolutePathForCrashReport(Frame frame) {
    if (frame.uri.scheme != 'dart' && frame.uri.scheme != 'package')
      return frame.uri.pathSegments.last;

    return '${frame.uri}';
  }
}
