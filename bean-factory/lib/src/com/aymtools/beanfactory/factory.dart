import 'package:bean_factory/bean_factory.dart';
import 'package:bean_factory/src/com/aymtools/beanfactory/type_adapter.dart';

/// 构造函数中取类型map参数时要慎重，如果未指定参数描述注解 则有可能取得的是uri的query参数亦或者传入的map对象
/// 所以取类型map参数时 最好注明在所有传入参数中的key  否则不一定会得到什么  优先会传入uri的query参数亦或者传入的map对象

abstract class IBeanFactory {
  dynamic getBeanInstance(String uri,
      {dynamic params, bool canThrowException = false});

  dynamic invokeMethod(dynamic bean, String methodName,
      {Map<String, dynamic> params, bool canThrowException = true});

  dynamic getFieldValue(dynamic bean, String fieldName,
      {bool canThrowException = true});

  void setFieldValue(dynamic bean, String fieldName, dynamic value,
      {bool canThrowException = true});

  Map<String, dynamic> getFieldValues(dynamic bean,
      {bool canThrowException = true});

  void setFieldValues(dynamic bean, Map<String, dynamic> values,
      {bool canThrowException = true});

  List<String> loadFactoryInitializer();

  List<String> loadTypeAdapter();
}

class BeanFactory implements IBeanFactory {
  BeanFactory._();

  static BeanFactory _instance = BeanFactory._();

  factory BeanFactory() => _instance;

  static BeanFactory get instance => _instance;

  IBeanFactory _factory;

  Map<Type, Map<Type, TypeConvert>> _typeAdapter = {};

  void bindFactory(IBeanFactory factory) {
    if (this._factory == null) {
      _factory = factory;
      factory
          .loadFactoryInitializer()
          .map((e) => factory.getBeanInstance(e))
          .where((element) => element != null && element is FactoryInitializer)
          .map((e) => e as FactoryInitializer)
          .forEach((element) {
        element.onInit(this);
      });
    }
  }

  static void registerFactory(IBeanFactory factory) {
    BeanFactory().bindFactory(factory);
  }

//  static List<String>
//
//  static void registerTypeAdapter(String typeAdapterBeanUri) {
//
//  }
//
//  static void registerFactoryInitializer(String factoryInitializerBeanUri) {
//
//  }

  void registerTypeAdapter2(String typeAdapterBeanUri) {
    registerTypeAdapter(getSingleBeanAndAs(typeAdapterBeanUri));
  }

  void registerTypeAdapter(TypeConvert convert) {
    assert(convert.to == Object, 'Cannot $convert to Object');
    _typeAdapter[convert.from][convert.to] = convert;
  }

  static String getBeanUri(Uri u) {
    String uri;
    List<String> pathSegments = u.pathSegments;
//    String namedConstructorInUri = "";
    if (pathSegments.length > 0) {
      String lastPathS = pathSegments[pathSegments.length - 1];
      int lastPathSF = lastPathS.lastIndexOf(".");
      if (lastPathSF > -1) {
//        namedConstructorInUri = lastPathS.substring(lastPathSF + 1);
        String lastPathRe = lastPathS.substring(0, lastPathSF);
        pathSegments = List.from(pathSegments, growable: false);
        pathSegments[pathSegments.length - 1] = lastPathRe;
        u = u.replace(pathSegments: pathSegments);
      } else {
//        namedConstructorInUri = "";
      }
    } else {
      //如果是如 factory://test.named 也可以尝试进行解析  但如 factory://xxxx.test.named 为了安全起见 不解析 最好遵照uri的标准用法
      if (u.hasAuthority &&
          u.authority.indexOf(":") == -1 &&
          u.authority.indexOf(".") == u.authority.lastIndexOf(".")) {
        String authority = u.authority;
        int ni = authority.lastIndexOf(".");
//        namedConstructorInUri = ni > -1 ? authority.substring(ni + 1) : "";
        String newAuthority = ni > -1 ? authority.substring(0, ni) : authority;
        u = u.replace(host: newAuthority);
      }
    }
    u = u.replace(queryParameters: {});

    uri = u.toString();

    if (uri.endsWith("?")) {
      uri = uri.substring(0, uri.length - 1);
    }
    return uri;
  }

  static String getNamedConstructorInUri(Uri u) {
    List<String> pathSegments = u.pathSegments;
    String namedConstructorInUri = "";
    if (pathSegments.length > 0) {
      String lastPathS = pathSegments[pathSegments.length - 1];
      int lastPathSF = lastPathS.lastIndexOf(".");
      if (lastPathSF > -1) {
        namedConstructorInUri = lastPathS.substring(lastPathSF + 1);
        String lastPathRe = lastPathS.substring(0, lastPathSF);
        pathSegments = List.from(pathSegments, growable: false);
        pathSegments[pathSegments.length - 1] = lastPathRe;
        u = u.replace(pathSegments: pathSegments);
      } else {
        namedConstructorInUri = "";
      }
    } else {
      //如果是如 factory://test.named 也可以尝试进行解析  但如 factory://xxxx.test.named 为了安全起见 不解析 最好遵照uri的标准用法
      if (u.hasAuthority &&
          u.authority.indexOf(":") == -1 &&
          u.authority.indexOf(".") == u.authority.lastIndexOf(".")) {
        String authority = u.authority;
        int ni = authority.lastIndexOf(".");
        namedConstructorInUri = ni > -1 ? authority.substring(ni + 1) : "";
        String newAuthority = ni > -1 ? authority.substring(0, ni) : authority;
        u = u.replace(host: newAuthority);
      }
    }
    return namedConstructorInUri;
  }

  static Map<String, dynamic> _singleInstanceBean = {};

  @override
  dynamic getBeanInstance(String uri,
          {dynamic params, bool canThrowException = false}) =>
      _factory?.getBeanInstance(uri,
          params: params, canThrowException: canThrowException);

  dynamic getSingleBeanInstance(String uri, {bool canThrowException = false}) {
    uri = getBeanUri(Uri.parse(uri));
    if (_singleInstanceBean.containsKey(uri)) return _singleInstanceBean[uri];
    dynamic bean = getBeanInstance(uri, canThrowException: canThrowException);
    if (bean != null) _singleInstanceBean[uri] = bean;
    return bean;
  }

  @override
  dynamic invokeMethod(bean, String methodName,
          {Map<String, dynamic> params, bool canThrowException = true}) =>
      _factory?.invokeMethod(bean, methodName,
          params: params, canThrowException: canThrowException);

  @override
  void setFieldValue(dynamic bean, String fieldName, dynamic value,
          {bool canThrowException = true}) =>
      _factory?.setFieldValue(bean, fieldName, value,
          canThrowException: canThrowException);

  @override
  void setFieldValues(bean, Map<String, dynamic> values,
          {bool canThrowException = true}) =>
      _factory?.setFieldValues(bean, values,
          canThrowException: canThrowException);

  @override
  dynamic getFieldValue(bean, String fieldName,
          {bool canThrowException = true}) =>
      _factory?.getFieldValue(bean, fieldName,
          canThrowException: canThrowException);

  @override
  Map<String, dynamic> getFieldValues(dynamic bean,
          {bool canThrowException = true}) =>
      _factory?.getFieldValues(bean, canThrowException: canThrowException);

  static T getBeanAndAs<T>(String uri,
      {dynamic params, bool canThrowException = false}) {
    return instance.getBeanInstance(uri,
        params: params, canThrowException: canThrowException) as T;
  }

  static dynamic getBean(String uri,
      {dynamic params, bool canThrowException = false}) {
    return instance.getBeanInstance(uri,
        params: params, canThrowException: canThrowException);
  }

  static T getSingleBeanAndAs<T>(String uri, {bool canThrowException = false}) {
    return instance.getSingleBeanInstance(uri,
        canThrowException: canThrowException) as T;
  }

  static dynamic getSingleBean(String uri, {bool canThrowException = false}) {
    return instance.getSingleBeanInstance(uri,
        canThrowException: canThrowException);
  }

  static dynamic invokeMethodS(dynamic bean, String methodName,
          {Map<String, dynamic> params, bool canThrowException = true}) =>
      instance.invokeMethod(bean, methodName,
          params: params, canThrowException: canThrowException);

  static dynamic getFieldValueS(dynamic bean, String fieldName,
          {bool canThrowException = true}) =>
      instance.getFieldValue(bean, fieldName,
          canThrowException: canThrowException);

  static void setFieldValueS(dynamic bean, String fieldName, dynamic value,
          {bool canThrowException = true}) =>
      instance.setFieldValue(bean, fieldName, value,
          canThrowException: canThrowException);

  static Map<String, dynamic> getAllFieldValue(dynamic bean,
          {bool canThrowException = true}) =>
      instance.getFieldValues(bean, canThrowException: canThrowException);

  static void setFieldValueByMap(dynamic bean, Map<String, dynamic> values,
          {bool canThrowException = true}) =>
      instance.setFieldValues(bean, values,
          canThrowException: canThrowException);

  static To convertTypeS<To>(dynamic from) => instance.convertType(from);

  To convertType<To>(dynamic from) {
    if (from == null) return null;
    if (from is To) return from;
    Type fromType = from.runtimeType;
    if (fromType == To) {
      return from as To;
    } else if (hasTypeAdapter(fromType, To)) {
      TypeConvert converter = _typeAdapter[fromType][To];
      return converter.convert(from);
    }
    return from as To;
  }

  static bool hasTypeAdapterS(Type from, Type to) =>
      instance.hasTypeAdapter(from, to);

  static bool hasTypeAdapterS1<From>(Type to) =>
      instance.hasTypeAdapter(From, to);

  static bool hasTypeAdapterS2<To>(Type from) =>
      instance.hasTypeAdapter(from, To);

  static bool hasTypeAdapterS2Value<To>(dynamic fromValue) => fromValue == null
      ? true
      : (fromValue is To) || hasTypeAdapterS2<To>(fromValue.runtimeType);

  static bool hasTypeAdapterS3<From, To>() => instance.hasTypeAdapter(From, To);

  bool hasTypeAdapter(Type from, Type to) =>
      from == to ||
      Object == to ||
      (_typeAdapter.containsKey(from) && _typeAdapter[from].containsKey(to));

  @override
  List<String> loadTypeAdapter() => _factory?.loadTypeAdapter() ?? [];

  @override
  List<String> loadFactoryInitializer() =>
      _factory?.loadFactoryInitializer() ?? [];
}

//class _BeanFactory extends BeanFactory {
//  _BeanFactory() : super.factory();
//  BeanFactory _factory;
//  static Map<String, dynamic> _singleInstanceBean = {};
//
//  @override
//  dynamic getBeanInstance(String uri, {dynamic params}) =>
//      _factory?.getBeanInstance(uri, params: params);
//
//  @override
//  dynamic getSingleBeanInstance(String uri) {
//    uri = getBeanUri(Uri.parse(uri));
//    if (_singleInstanceBean.containsKey(uri)) return _singleInstanceBean[uri];
//    dynamic bean = getBeanInstance(uri);
//    _singleInstanceBean[uri] = bean;
//    return bean;
//  }
//
//  @override
//  dynamic invokeMethod(bean, String methodName,
//          {Map<String, dynamic> params}) =>
//      _factory?.invokeMethod(bean, methodName, params: params);
//
//  @override
//  void setFieldValue(dynamic bean, String fieldName, dynamic value) =>
//      _factory?.setFieldValue(bean, fieldName, value);
//
//  @override
//  void setFieldValues(bean, Map<String, dynamic> values) =>
//      _factory?.setFieldValues(bean, values);
//
//  @override
//  dynamic getFieldValue(bean, String fieldName) =>
//      _factory.getFieldValue(bean, fieldName);
//
//  @override
//  Map<String, dynamic> getFieldValues(dynamic bean) =>
//      _factory.getFieldValues(bean);
//}
