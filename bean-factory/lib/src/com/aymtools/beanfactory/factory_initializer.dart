import 'package:bean_factory/src/com/aymtools/beanfactory/core.dart';
import 'package:bean_factory/src/com/aymtools/beanfactory/factory.dart';

abstract class FactoryInitializer {
  void onInit(BeanFactory factory);
}

class OnFactoryInitializer extends Bean {
  const OnFactoryInitializer(String initializerName)
      : super(
          scanConstructors: false,
          key:
              initializerName == null ? '' : 'initializer://' + initializerName,
          keyGen: const KeyGenByUri(),
        );
}
