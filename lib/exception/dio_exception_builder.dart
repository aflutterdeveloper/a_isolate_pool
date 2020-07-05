import 'package:dio/dio.dart';

import 'a_exception.dart';
import 'a_exception_factory.dart';

class DioExceptionBuilder implements AExceptionBuilder {
  @override
  AException build(anyException, stack) {
    if (anyException is DioError) {
      if (anyException.error is AException) {
        return anyException.error;
      }
    }
    return null;
  }
}
