/// 定义Bean生成器注解 dart特殊机制 自动化的入口
class Factory {
  ///表示存在在其他类库中的 Bean 路径 可以自动分模块引用 当当前模块优先级 最高
  final List<Type> otherFactory;

  ///表示存在在其他类库中的 Bean 路径 可以自动分模块引用 当当前模块优先级 最高
  final List<String> otherImports;

  ///自定义key生成器
//  final List<KeyGen> otherKeyGen;

  const Factory({
    this.otherFactory = const [],
    this.otherImports = const [],
//    this.otherKeyGen = const [],
  });
}

/// 定义类库相关的Bean类自动导出 就是写库 让库中的 Bean BeanCreator 自动生成lib文件
class FactoryLibExport {
  const FactoryLibExport();
}

/// 定义Bean的注解
class Bean {
  final String uri;
  final String tag;
  final int ext;
  final KeyGen keyGen;
  ///必须是继承目标或实现目标的类
  final List<Type> needAssignableFrom;

  const Bean({
    this.uri = "",
    this.tag = "",
    this.ext = -1,
    this.keyGen = const KeyGenByUri(),
    this.needAssignableFrom = const [],
  });
}

/// 指定Bean的构造函数 结合 BeanCreateParam 来指定参数来源 不指定参数来源视为无参构造
/// 只可以使用在命名构造函数上 使用在默认构造函数上时 namedConstructor 会生成两种构造路径
/// "" 代表默认构造函数 就是非命名构造函数
class BeanConstructor {
  final String namedConstructor;

  const BeanConstructor({this.namedConstructor = ""});
}

/// Bean构造函数或factory参数指定在map参数中的名字
class BeanCreateParam {
  final String keyInMap;

  const BeanCreateParam(this.keyInMap);
}

/// 自定义Bean生成器 定义的类必须继承 BeanCustomCreatorBase
class BeanCreator {
  final String uri;

  const BeanCreator(this.uri);
}

////一下都是tools

///定义查找Bean的根据的键 返回结果为uri
abstract class KeyGen {
  String gen(String uri, String tag, int ext, String className, String libUri);
}

///直接使用传入的uri来生成
class KeyGenByUri implements KeyGen {
  const KeyGenByUri();

  @override
  String gen(
          String uri, String tag, int ext, String className, String libUri) =>
      uri;
}

///自动生成 /类库路径首字母小写的类名 如package:bean_factory/bean_factory.dart中的BeanInfo  生成结果为/bean_factory/bean_factory/beanInfo
class KeyGenByClassName implements KeyGen {
  const KeyGenByClassName();

  @override
  String gen(String uri, String tag, int ext, String className, String libUri) {
    String url = libUri;
    if (url.endsWith(".dart")) url = url.substring(0, libUri.length - 6);
    url = url.replaceFirst("package:", "").replaceAll(".", "/");
    String simpleName =
        "/${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
    return "/$url$simpleName";
  }
}

///自动生成 /首字母小写的类名 如BeanInfo  生成结果为/beanInfo  有可能产生冲突的结果
class KeyGenByClassSimpleName implements KeyGen {
  const KeyGenByClassSimpleName();

  @override
  String gen(
          String uri, String tag, int ext, String className, String libUri) =>
      "/${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
}

///自动生成 /bean/bean$num  num自动增长
class KeyGenBySequence implements KeyGen {
  static int next = 0;

  const KeyGenBySequence();

  @override
  String gen(
          String uri, String tag, int ext, String className, String libUri) =>
      "/bean/bean${++next}";
}

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
  Bean create(String namedConstructorInRouter, Map<String, dynamic> mapParams,
      dynamic objParam);
}