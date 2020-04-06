import 'package:bean_factory/bean_factory.dart';

abstract class TypeConvert<From, To> {
  Type get from => From;

  Type get to => To;

  To convert(From value);
}

class TypeAdapter extends Bean {
  const TypeAdapter(String adapterName)
      : super(
            key: adapterName == null ? '' : 'typeAdapter://' + adapterName,
            keyGen: const KeyGenByUri());
}

@OnFactoryInitializer('LoadTypeAdapter')
class LoadTypeAdapter extends FactoryInitializer {
  @override
  void onInit(BeanFactory factory) {
    factory.loadTypeAdapter().forEach((element) {
      factory.registerTypeAdapter2(element);
    });
  }
}

@TypeAdapter('Int2String')
class Int2String extends TypeConvert<int, String> {
  @override
  String convert(int value) {
    return value.toString();
  }
}

@TypeAdapter('Boolean2String')
class Boolean2String extends TypeConvert<bool, String> {
  @override
  String convert(bool value) {
    return value.toString();
  }
}

@TypeAdapter('Double2String')
class Double2String extends TypeConvert<double, String> {
  @override
  String convert(double value) {
    return value.toString();
  }
}

@TypeAdapter('String2Int')
class String2Int extends TypeConvert<String, int> {
  @override
  int convert(String value) {
    return int.tryParse(value);
  }
}

@TypeAdapter('String2Boolean')
class String2Boolean extends TypeConvert<String, bool> {
  @override
  bool convert(String value) {
    return value == 'true';
  }
}

@TypeAdapter('String2Double')
class String2Double extends TypeConvert<String, double> {
  @override
  double convert(String value) {
    return double.tryParse(value);
  }
}
