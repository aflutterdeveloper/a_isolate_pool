import 'package:a_thread_pool/exception/a_exception.dart';
import 'package:a_thread_pool/exception/a_exception_factory.dart';
import 'package:dio/dio.dart';

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