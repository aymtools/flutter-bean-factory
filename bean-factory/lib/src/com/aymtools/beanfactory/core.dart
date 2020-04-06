/// 定义Bean生成器注解 dart特殊机制 自动化的入口
class Factory {
  ///表示存在在其他类库中的 Bean 路径 可以自动分模块引用 当前模块优先级 最高  被指明的类必须使用 FactoryLibExport注解
  @Deprecated('use importLibsName')
  final List<Type> otherFactory;

  ///表示主动导入到生成文件的import上 无意义，默认会自动寻找需要导入的文件
  @Deprecated('not uesd')
  final List<String> otherImports;

  final List<String> importLibsName;

  final bool isGenFactory;
  final bool isGenLibExport;

  static const int GEN_GROUP_BY_NONE = 0;
  static const int GEN_GROUP_BY_SCHEME = 1;

  ///自动根据不同策略生成调用器的顺序，有可能增加调用器的执行效率 暂未实现
  final int genGroupBy;

  const Factory({
    this.otherFactory = const [],
    List<String> otherImports = const [],
    this.isGenFactory = true,
    this.isGenLibExport = false,
    List<String> importLibsName,
    int genGroupBy = GEN_GROUP_BY_NONE,
  })  : this.genGroupBy = 0,
        this.importLibsName = importLibsName ?? const [],
        this.otherImports = const [];
}

/// 定义类库相关的Bean类自动导出 就是写库 让库中的 Bean BeanCreator 自动生成lib文件
@Deprecated('use Factory')
class BeanFactoryLibExport extends Factory {
  const BeanFactoryLibExport({List<String> importLibsName})
      : super(
            isGenFactory: false,
            isGenLibExport: true,
            importLibsName: importLibsName);
}

abstract class _BeanBase {
  final String key;
  final String tag;
  final int ext;
  final bool flag;
  final Type extType;
  final String tag1;
  final int ext1;
  final bool flag1;

  final List<String> tagList;
  final List<int> extList;
  final List<Type> extTypeList;

  const _BeanBase(
      {this.key,
      this.tag,
      this.ext,
      this.flag,
      this.extType,
      this.tag1,
      this.ext1,
      this.flag1,
      this.tagList,
      this.extList,
      this.extTypeList});
}

/// 定义Bean的注解
class Bean extends _BeanBase {
  final KeyGen keyGen;

  ///必须是继承目标或实现目标的类
  final List<Type> needAssignableFrom;

  final bool scanConstructors;
  final bool scanConstructorsUsedBlackList;
  final bool scanMethods;
  final bool scanMethodsUsedBlackList;
  final bool scanSuperMethods;
  final bool scanFields;
  final bool scanFieldsUsedBlackList;
  final bool scanSuperFields;

  const Bean({
    String key = "",
    String tag = "",
    int ext = -1,
    bool flag = false,
    String tag1 = "",
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
    this.keyGen = const KeyGenByUri(),
    this.needAssignableFrom = const [],
    this.scanConstructors = true,
    this.scanConstructorsUsedBlackList = false,
    this.scanMethods = false,
    this.scanMethodsUsedBlackList = false,
    this.scanSuperMethods = false,
    this.scanFields = false,
    this.scanFieldsUsedBlackList = false,
    this.scanSuperFields = false,
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);

//  bool get isNeedScanConstructors => scanConstructors;
//
//  bool get isNeedScanMethods => scanMethods || scanSuperMethods;
//
//  bool get isNeedScanSuperMethods => scanSuperMethods;
//
//  bool get isNeedScanFields => scanFields || scanSuperFields;
//
//  bool get isNeedScanSuperFields => scanSuperMethods;
}

/// 指定Bean的构造函数 结合 BeanCreateParam 来指定参数来源 不指定参数来源视为无参构造
/// 只可以使用在命名构造函数上 使用在默认构造函数上时  会生成两种构造路径
/// "" 代表默认构造函数 就是非命名构造函数
class BeanConstructor extends _BeanBase {
  const BeanConstructor({
    String namedConstructor = "",
    String tag = "",
    int ext = -1,
    bool flag = false,
    String tag1 = "",
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: namedConstructor,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

///黑名单模式模式时有效 不扫描的构造函数
class BeanConstructorNot {
  const BeanConstructorNot();
}

///一般用来测试接受到的参数 构造函数 必须为两个参数 的第一个参数为dynamic类型(调用者传入参数) 第二个为Map<String,dynamic>(uri中参数) 类型 若不符要求则不识别当前的构造函数
class BeanConstructorFor2Params extends BeanConstructor {
  const BeanConstructorFor2Params({
    String namedConstructor = "",
    String tag = "",
    int ext = -1,
    bool flag = false,
    String tag1 = "",
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            namedConstructor: namedConstructor,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

/// Bean构造函数或factory或方法体参数指定在map参数中的名字
class BeanParam extends _BeanBase {
  const BeanParam({
    String key = "",
    String tag = "",
    int ext = -1,
    bool flag = false,
    String tag1 = "",
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

class BeanConstructorParam extends BeanParam {
  const BeanConstructorParam({String keyInMap}) : super(key: keyInMap);
}

class BeanMethod extends _BeanBase {
  const BeanMethod({
    String key = "",
    String tag = "",
    int ext = -1,
    bool flag = false,
    String tag1 = "",
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

///黑名单模式模式时有效 不扫描的方法
class BeanMethodNot {
  const BeanMethodNot();
}

///
class BeanMethodParam extends BeanParam {
  const BeanMethodParam(String keyInMap) : super(key: keyInMap);
}

class BeanField extends _BeanBase {
  const BeanField({
    String key = "",
    String tag = "",
    int ext = -1,
    bool flag = false,
    String tag1 = "",
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

///黑名单模式模式时有效 不扫描的属性
class BeanFieldNot {
  const BeanFieldNot();
}

/// 自定义Bean生成器 定义的类必须继承 BeanCustomCreatorBase
class BeanCreator {
  final String key;

  const BeanCreator(this.key);
}

////一下都是tools

///定义查找Bean的根据的键 返回结果为uri
abstract class KeyGen {
  String gen(String key, String tag, int ext, String className, String libUri);
}

///直接使用传入的uri来生成
class KeyGenByUri implements KeyGen {
  const KeyGenByUri();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      key;
}

///自动生成 /类库路径首字母小写的类名 如package:bean_factory/bean_factory.dart中的BeanInfo  生成结果为/bean_factory/bean_factory/beanInfo
class KeyGenByClassName implements KeyGen {
  const KeyGenByClassName();

  @override
  String gen(String key, String tag, int ext, String className, String libUri) {
    String url = libUri;
    if (url.endsWith(".dart")) url = url.substring(0, libUri.length - 5);
    if (url.startsWith('package:')) {
      url = url.replaceFirst('package:', '');
      if (url.indexOf('/') > 0) {
        String scheme = url.substring(0, url.indexOf('/'));
        url = url.substring(url.indexOf('/') + 1);
        url = scheme + '://' + url;
      } else {
        url = url.replaceAll(".", "_");
        url = '/' + url;
      }
    } else {
      url = url.replaceAll(".", "_");
      url = '/' + url;
    }
    String simpleName =
        "${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
    return "$url/$simpleName";
  }
}

///自动生成 /首字母小写的类名 如BeanInfo  生成结果为/beanInfo  有可能产生冲突的结果
class KeyGenByClassSimpleName implements KeyGen {
  const KeyGenByClassSimpleName();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      "/${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
}

///自动生成 /bean/bean$num  num自动增长
class KeyGenBySequence implements KeyGen {
  static int next = 0;

  const KeyGenBySequence();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      "/bean/bean${++next}";
}

///
//class KeyGenByAddPrefix extends KeyGenByUri {
//  final String scheme;
//  final String authority;
//
//  const KeyGenByAddPrefix(String scheme, String authority)
//      : this.scheme = scheme ?? '',
//        this.authority = authority ?? '';
//
//  @override
//  String gen(String key, String tag, int ext, String className, String libUri) {
//    Uri uri = Uri.parse(key);
//    if (scheme.isNotEmpty && !uri.hasScheme) {
//      uri.replace(scheme: scheme);
//      uri.replace(host: scheme);
//    }
//    return super.gen(key, tag, ext, className, libUri);
//  }
//}

E findFistWhere<E>(List<E> list, bool test(E element), {E orElse = null}) {
  for (E element in list) {
    if (test(element)) return element;
  }
  return orElse;
}

List<E> cloneList<E>(List<E> source, E cloneFun(E e)) {
  return List.generate(source.length, (e) => cloneFun(source[e]),
      growable: true);
}

class Pair<K, V> {
  K key;
  V value;

  Pair(this.key, this.value);
}

class BoxThree<A, B, C> {
  A a;
  B b;
  C c;

  BoxThree(this.a, this.b, this.c);
}

///自定义Bean的生成器 不在提供Bean的配置信息 自己完全自定义 一个uri对应一个生成策略
abstract class BeanCustomCreatorBase<Bean> {
  Bean create(String namedConstructorInUri, dynamic param,
      Map<String, String> uriParams, bool canThrowException);
}

class BeanNotFoundException implements Exception {
  final String uri;
  final message;

  BeanNotFoundException(this.uri, {this.message});

  String toString() {
    String def =
        "BeanNotFoundException:\n For ${uri} cann not found Bean config!";
    if (message == null) return def;
    return "$def: $message";
  }
}

class NoSuchMethodException implements Exception {
  final Type type;
  final String methodName;
  final message;

  NoSuchMethodException(this.type, this.methodName, {this.message});

  String toString() {
    String def = "NoSuchMethodException:\n${type} : $methodName not found !";
    if (message == null) return def;
    return "$def: $message";
  }
}

class NoSuchFieldException implements Exception {
  final Type type;
  final String fieldName;
  final message;

  NoSuchFieldException(this.type, this.fieldName, {this.message});

  String toString() {
    String def = "NoSuchFieldException:\n${type} : $fieldName not found !";
    if (message == null) return def;
    return "$def: $message";
  }
}

class IllegalArgumentException implements Exception {
  final Type type;
  final String name;
  final List<Pair<String, Type>> paramsTypes;
  final List<Pair<String, Type>> valuesTypes;
  final message;

  IllegalArgumentException(
      this.type, this.name, this.paramsTypes, this.valuesTypes,
      {this.message});

  String toString() {
    String def =
        "IllegalArgumentException:\n${type} : $name illegal argument ! \n need params : ${paramsTypes} \n values params ${valuesTypes}";
    if (message == null) return def;
    return "$def: $message";
  }
}
