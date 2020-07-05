import 'dart:convert';

import 'a_exception.dart';
import 'error_format.dart';

/// isolate异常转化工厂, 使异常能够在isolate间传递
class AExceptionFactory {
  List<AExceptionBuilder> builderList = List<AExceptionBuilder>();
  final AExceptionBuilder defaultBuilder = _DefaultAExceptionBuilder();

  /// 注入异常转化器 builder
  void addBuilder(AExceptionBuilder builder) {
    builderList.add(builder);
  }

  /// 注销异常转化器 builder
  void removeBuilder(AExceptionBuilder builder) {
    builderList.remove(builder);
  }

  /// 将anyException转化为可传递的AException
  /// 如果您从AException派生了异常类，请确保你的异常实现类中不要包含Lambda表达式函数或其它block函数
  AException build(dynamic anyException, dynamic stack) {
    for (AExceptionBuilder builder in builderList) {
      final aException = builder.build(anyException, stack);
      if (null != aException) {
        return aException;
      }
    }

    if (anyException is AException) {
      return anyException;
    }
    return defaultBuilder.build(anyException, stack);
  }
}

abstract class AExceptionBuilder {
  AException build(dynamic anyException, dynamic stack);
}

class _DefaultAExceptionBuilder implements AExceptionBuilder {
  @override
  AException build(err, stack) {
    if (null == err) {}
    final errorStack = StackFormat(stack).toJson();
    String errorMessage = json.encode({
      'type': '${err.runtimeType}',
      'value': errorStack,
    });

    return AException(errorMessage, exceptionType: err.runtimeType);
  }
}
