const String codeTemplate = """
{{#imports}}
{{{importsPath}}}
{{/imports}}

class BeanFactoryInstance implements IBeanFactory{
  BeanFactoryInstance._();

  static BeanFactoryInstance _instance = BeanFactoryInstance._();
  
  static bool isRegistered = false;

  static void register() {
    if (isRegistered) return;
    isRegistered = true;
    BeanFactory.registerFactory(_instance);
  }
   
  @override
  dynamic getBeanInstance(String uri, {dynamic params, bool canThrowException = false}) {
//    Map<String, dynamic> mapParam = {};
//    dynamic objParam;

    try {
      Uri u = Uri.parse(uri);
      List<String> pathSegments = u.pathSegments;

      Map<String, dynamic> queryParameters = u.queryParameters;
      Map<String, List<String>> queryParametersAll = u.queryParametersAll;
      String namedConstructorInUri = "";
      if (pathSegments.length > 0) {
        String lastPathS = pathSegments[pathSegments.length - 1];
        int lastPathSF = lastPathS.lastIndexOf(".");
        if(lastPathSF > -1){
          namedConstructorInUri=lastPathS.substring(lastPathSF + 1);
          String lastPathRe = lastPathS.substring(0, lastPathSF);
          pathSegments = List.from(pathSegments, growable: false);
          pathSegments[pathSegments.length - 1] = lastPathRe;
          u = u.replace(pathSegments: pathSegments);
        }else{
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
          String newAuthority =
              ni > -1 ? authority.substring(0, ni) : authority;
          u = u.replace(host: newAuthority);
        }
      }
      u = u.replace(queryParameters: {});

      uri = u.toString();

      if (uri.endsWith("?")) {
        uri = uri.substring(0, uri.length - 1);
      }
      
//      if (queryParameters.length > 0) {
//        mapParam.addAll(queryParameters);
//        if (params is Map<String, dynamic>) {
//          mapParam.addAll(params);
//        }
//        objParam = params;
//      } else if (params is Map<String, dynamic>) {
//        mapParam = params;
//        objParam = params;
//      } else {
//        mapParam = null;
//        objParam = params;
//      }

      dynamic result;

      if (result == null) {
        result = _createBeanInstanceByCustomCreator(
            uri, namedConstructorInUri, params, queryParameters, canThrowException);
      }
      if (result == null) {
        result = _createBeanInstanceBySysCreator(
            uri, namedConstructorInUri, params, queryParameters, canThrowException);
      }
      if (result == null &&canThrowException){
        throw BeanNotFoundException(uri);
      }
      return result;
    } catch (e) {
      print(e);
      if (canThrowException) throw e;
      return null;
    }
  }
    
  dynamic _createBeanInstanceByCustomCreator(String uri, String namedConstructorInUri, dynamic param,
      Map<String, String> uriParams, bool canThrowException) {
     switch (uri) {
        {{{createBeanInstanceByCustomCreator}}}
        default: 
        return null;
     }
  }
  
  dynamic _createBeanInstanceBySysCreator(String uri, String namedConstructorInUri, dynamic param,
      Map<String, String> uriParams, bool canThrowException) {
     switch (uri) {
        {{{createBeanInstanceBySysCreator}}}
        default: 
        return null;
     }
  }
    
  @override
  dynamic invokeMethod(dynamic bean, String methodName,
      {Map<String, dynamic> params, bool canThrowException = true}) {
    switch (bean.runtimeType) {
       {{{invokeMethods}}}
    }
    if(canThrowException)
      throw NoSuchMethodException(bean.runtimeType , methodName);
  }
  
  @override
  dynamic getFieldValue(dynamic bean, String fieldName, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{getFields}}}
    }
    if(canThrowException)
      throw NoSuchFieldException(bean.runtimeType , fieldName);
  }

  @override
  void setFieldValue(dynamic bean, String fieldName, dynamic value, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{setFields}}}
    }
    if(canThrowException)
      throw NoSuchFieldException(bean.runtimeType , fieldName);
  }

  @override
  Map<String, dynamic> getFieldValues(dynamic bean, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{getAllFields}}}
    }
    return {};
  }
  
  @override
  void setFieldValues(dynamic bean, Map<String, dynamic> values, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{setAllFields}}}
    }
  }
  
  @override
  List<String> loadTypeAdapter() => <String>[{{{typeAdapters}}}];
  
  @override
  List<String> loadFactoryInitializer() => <String>[{{{initializers}}}];
}
""";

const String codeTemplateBackup = """
{{#imports}}
{{{importsPath}}}
{{/imports}}

/// 构造函数中取类型map参数时要慎重，如果未指定参数描述注解 则有可能取得的是uri的query参数亦或者传入的map对象
/// 所以取类型map参数时 最好注明在所有传入参数中的key  否则不一定会得到什么  优先会传入uri的query参数亦或者传入的map对象

class BeanFactory {
  static BeanFactory get instance => _getInstance();
  static BeanFactory _instance;

  BeanFactory._internal();

  factory BeanFactory() => _getInstance();

  static BeanFactory _getInstance() {
    if (_instance == null) {
      _instance = BeanFactory._internal();
    }
    return _instance;
  }
  
  static Map<String, dynamic> _singleInstanceBean = {};

  static T getBeanAndAs<T>(String uri, {dynamic params}) {
    return instance.getBeanInstance(uri, params: params) as T;
  }

  static dynamic getBean(String uri, {dynamic params}) {
    return instance.getBeanInstance(uri, params: params);
  }

  static T getSingleBeanAndAs<T>(String uri) {
    return instance.getSingleBeanInstance(uri) as T;
  }

  static dynamic getSingleBean(String uri) {
    return instance.getSingleBeanInstance(uri);
  }

  dynamic getSingleBeanInstance(String uri) {
    uri = getBeanUri(Uri.parse(uri));
    if (_singleInstanceBean.containsKey(uri)) return _singleInstanceBean[uri];
    dynamic bean = getBeanInstance(uri);
    _singleInstanceBean[uri] = bean;
    return bean;
  }

  dynamic getBeanInstance(String uri, {dynamic params}) {
    Map<String, dynamic> mapParam = {};
    dynamic objParam;

    try {
      Uri u = Uri.parse(uri);
      List<String> pathSegments = u.pathSegments;

      Map<String, dynamic> queryParameters = u.queryParameters;
      Map<String, List<String>> queryParametersAll = u.queryParametersAll;
      String namedConstructorInUri = "";
      if (pathSegments.length > 0) {
        String lastPathS = pathSegments[pathSegments.length - 1];
        int lastPathSF = lastPathS.lastIndexOf(".");
        if(lastPathSF > -1){
          namedConstructorInUri=lastPathS.substring(lastPathSF + 1);
          String lastPathRe = lastPathS.substring(0, lastPathSF);
          pathSegments = List.from(pathSegments, growable: false);
          pathSegments[pathSegments.length - 1] = lastPathRe;
          u = u.replace(pathSegments: pathSegments);
        }else{
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
          String newAuthority =
              ni > -1 ? authority.substring(0, ni) : authority;
          u = u.replace(host: newAuthority);
        }
      }
      u = u.replace(queryParameters: {});

      uri = u.toString();

      if (uri.endsWith("?")) {
        uri = uri.substring(0, uri.length - 1);
      }
      
      if (queryParameters.length > 0) {
        mapParam.addAll(queryParameters);
        if (params is Map<String, dynamic>) {
          mapParam.addAll(params);
        }
        objParam = params;
      } else if (params is Map<String, dynamic>) {
        mapParam = params;
        objParam = params;
      } else {
        mapParam = null;
        objParam = params;
      }

      dynamic result;

      if (result == null) {
        result = _createBeanInstanceByCustomCreator(
            uri, namedConstructorInUri, mapParam, objParam);
      }
      if (result == null) {
        result = _createBeanInstanceBySysCreator(
            uri, namedConstructorInUri, mapParam, objParam);
      }
      return result;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
  
  String getBeanUri(Uri u) {
    String uri;
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
    u = u.replace(queryParameters: {});

    uri = u.toString();

    if (uri.endsWith("?")) {
      uri = uri.substring(0, uri.length - 1);
    }
    return uri;
  }
  String getNamedConstructorInUri(Uri u) {
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
  
  dynamic _createBeanInstanceByCustomCreator(String uri, String namedConstructorInUri,
      Map<String, dynamic> mapParam, dynamic objParam) {
     switch (uri) {
        {{{createBeanInstanceByCustomCreator}}}
        default: 
        return null;
     }
  }
  
  dynamic _createBeanInstanceBySysCreator(String uri, String namedConstructorInUri,
      Map<String, dynamic> mapParam, dynamic objParam) {
     switch (uri) {
        {{{createBeanInstanceBySysCreator}}}
        default: 
        return null;
     }
  }
  
  static dynamic invokeMethodS(dynamic bean, String methodName,
          {Map<String, dynamic> params}) =>
      instance.invokeMethod(bean, methodName, params:params);
  
  
  dynamic invokeMethod(dynamic bean, String methodName,
      {Map<String, dynamic> params}) {
    switch (bean.runtimeType) {
       {{{invokeMethods}}}
    }
    throw NoSuchMethodException(bean.runtimeType , methodName);
  }
  
  static dynamic getFieldValue(dynamic bean, String fieldName)=>instance.getField(bean, fieldName);

  dynamic getField(dynamic bean, String fieldName) {
    switch (bean.runtimeType) {
        {{{getFields}}}
    }
    throw NoSuchFieldException(bean.runtimeType , fieldName);
  }

  static void setFieldValue(dynamic bean, String fieldName, dynamic value)=>instance.setField(bean, fieldName, value);

  void setField(dynamic bean, String fieldName, dynamic value) {
    switch (bean.runtimeType) {
        {{{setFields}}}
    }
    throw NoSuchFieldException(bean.runtimeType , fieldName);
  }

  static Map<String, dynamic> getAllFieldValue(dynamic bean)=>instance.getFields(bean);

  Map<String, dynamic> getFields(dynamic bean) {
    switch (bean.runtimeType) {
        {{{getAllFields}}}
    }
    return {};
  }

  static void setFieldValueByMap(dynamic bean, Map<String, dynamic> values)=>instance.setFields(bean, values);

  void setFields(dynamic bean, Map<String, dynamic> values) {
    switch (bean.runtimeType) {
        {{{setAllFields}}}
    }
  }
}
""";
