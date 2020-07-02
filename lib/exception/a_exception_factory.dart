
import 'dart:convert';

import 'package:a_thread_pool/a_thread_pool.dart';

import 'error_format.dart';


class AExceptionFactory {
   List<AExceptionBuilder> builderList = List<AExceptionBuilder>();
   AExceptionBuilder _default = _DefaultAExceptionBuilder();

   void addBuilder(AExceptionBuilder builder) {
      builderList.add(builder);
   }

   void removeBuilder(AExceptionBuilder builder) {
     builderList.remove(builder);
   }

   AException build(dynamic anyException, dynamic stack) {
      for(AExceptionBuilder builder in builderList) {
        final aException = builder.build(anyException, stack);
        if (null != aException) {
          return aException;
        }
      }
      return _default.build(anyException, stack);
   }
}

abstract class AExceptionBuilder {
  AException build(dynamic anyException, dynamic stack);
}

class _DefaultAExceptionBuilder implements AExceptionBuilder {
  @override
  AException build(err, stack) {
    final errorStack = ErrorFormat(err, stack).toJson();
    String errorMessage = json.encode({
      'type': '${err.runtimeType}',
      'value': errorStack,
    });

    return AException(errorMessage);
  }

}