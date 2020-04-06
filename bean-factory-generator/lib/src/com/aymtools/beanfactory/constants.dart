import 'package:analyzer/dart/element/type.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:bean_factory_generator/bean_factory_generator.dart';
import 'package:dart_style/dart_style.dart';

bool isNotInNotScanPackage(String pack) => !isInNotScanPackage(pack);

bool isInNotScanPackage(String pack) => _notScanPackage.contains(pack);
final List<String> _notScanPackage = [
  'bean_factory',
  'bean_factory_generator',
  'analyzer',
  'source_gen',
  'build',
  'mustache4dart',
  'reflectable',
  'build_runner',
  'mime',
  'io',
  'dart_style',
  'code_builder',
  'build_runner_core',
  'timing',
  'build_resolvers',
  'graphs',
  'build_daemon',
  'stream_transform',
  'shelf_web_socket',
  'web_socket_channel',
  'collection',
  'meta',
  'typed_data',
  'vector_math',
  'sky_engine',
  'flutter',
  'aym_router',
  'async',
  'charcode',
  'path',
  'term_glyph',
  'source_span',
  'string_scanner',
  'boolean_selector',
  'stack_trace',
  'stream_channel',
  'matcher',
  'test_api',
  'convert',
  'crypto',
  'args',
  'archive',
  'petitparser',
  'xml',
  'image',
  'quiver',
  'flutter_test',
  '_fe_analyzer_shared',
  'js',
  'node_interop',
  'node_io',
  'pedantic',
  'glob',
  'csslib',
  'html',
  'package_config',
  'pub_semver',
  'watcher',
  'yaml',
  'logging',
  'json_annotation',
  'checked_yaml',
  'pubspec_parse',
  'build_config',
  'built_collection',
  'fixnum',
  'built_value',
  'http_multi_server',
  'http_parser',
  'http',
  'package_resolver',
  'pool',
  'shelf',
  'aym_router',
  'aym_router_generator'
];

final Set<String> _scannedPackage = Set();

void addScannedPackage(String pack) => _scannedPackage.add(pack);

List<String> getScannedPackage() => List.from(_scannedPackage);

final List<String> _needScanPackage = [];

bool isNeedScanPackage(String pack) => _needScanPackage.contains(pack);

bool isNeedScanPackageEmpty() => _needScanPackage.isEmpty;

final writeDartFileFormatter = DartFormatter();

final Map<String, GBean> beanMap = {};
final Map<String, GBean> beanParseErrorMap = {};
final Map<String, GBeanCreator> beanCreatorMap = {};
final Map<String, GBeanCreator> beanSysCreatorMap = {};

Factory _factory;
String _beanFactoryCodeUri = '';
String _beanFactoryInvokerCodeUri = '';
Uri _beanFactoryInputUri;
String _packageName;

void setBeanFactory(
    Factory factory, Uri beanFactoryInputUri, String runWithPackageName) {
  if (factory == null) return;
  String factoryAnnotationDartCodeUri = beanFactoryInputUri.toString();
  if (factoryAnnotationDartCodeUri == null ||
      factoryAnnotationDartCodeUri.isEmpty) return;
  String wUri = factoryAnnotationDartCodeUri.substring(
      0, factoryAnnotationDartCodeUri.lastIndexOf("/") + 1);
  _beanFactoryCodeUri = wUri + 'beanfactory.aymtools.dart';
  _beanFactoryInvokerCodeUri = wUri + 'beanfactory.sys.aymtools.dart';
//  parseAddImports(_beanFactoryCodeUri);
  _imports[_beanFactoryInvokerCodeUri] = '';
  _beanFactoryInputUri = beanFactoryInputUri;
  _factory = factory;
  _packageName = runWithPackageName;
}

Factory get config => _factory;

String get beanFactoryCodeUri => _beanFactoryCodeUri;

String get beanFactoryInvokerCodeUri => _beanFactoryInvokerCodeUri;

Uri get beanFactoryInput => _beanFactoryInputUri;

String get runWithPackageName => _packageName;

///导入包配置 把默认的包先增加进去
final Map<String, String> _imports = {
  "package:bean_factory/bean_factory.dart": ""
};

Map<String, String> get imports => Map.from(_imports);

MapEntry<String, String> parseAddImport(DartType type) {
  String typeLibraryName = type.element.library.name;
  if ("dart.core" == typeLibraryName || type.element.library.isDartCore) {
    return MapEntry("", "");
  }
  if (type is ParameterizedType) {
    ParameterizedType parameterizedType = type;
    parameterizedType.typeArguments
        .forEach((element) => parseAddImport(element));
  }
  return parseAddImports(type.element.librarySource.uri.toString());
}

MapEntry<String, String> parseAddImports(String librarySourceUriStr) {
  if ("dart.core" == librarySourceUriStr ||
      librarySourceUriStr.startsWith('dart:')) {
    return MapEntry("", "");
  }
  if ("" == librarySourceUriStr || !librarySourceUriStr.endsWith(".dart"))
    return MapEntry(librarySourceUriStr, librarySourceUriStr);
  if (!_imports.containsKey(librarySourceUriStr)) {
    String asStr = _formatAsStr(librarySourceUriStr);
    _imports[librarySourceUriStr] = asStr;
  }
  return MapEntry(librarySourceUriStr, _imports[librarySourceUriStr]);
}

String getImportAsStr(String librarySourceUriStr) =>
    _imports.containsKey(librarySourceUriStr)
        ? _imports[librarySourceUriStr]
        : '';

String _formatAsStr(String uri) {
  if ("" == uri || !uri.endsWith(".dart")) return uri;
  String asStr = uri
      .substring(0, uri.length - 5)
      .replaceAll("/", "_")
      .replaceFirst("package:", "")
      .replaceAllMapped(RegExp(r"_\w"), (match) => match.group(0).toUpperCase())
      .replaceAll("_", "");
  if (asStr.indexOf(".") > -1) {
    asStr = asStr
        .replaceAllMapped(
            RegExp(r"\.\w"), (match) => match.group(0).toUpperCase())
        .replaceAll(".", "");
  }
  if (asStr.length > 1) {
    asStr = asStr[0].toUpperCase() + asStr.substring(1);
  }
  int i = 0;
  String asStrTemp = asStr;
  while (_imports.containsValue(asStrTemp)) {
    i++;
    asStrTemp = '${asStr}_$i';
  }
  return asStrTemp;
}

final Map<String, KeyGen> keyGens = {
  "KeyGenByUri": KeyGenByUri(),
  "KeyGenBySequence": KeyGenBySequence(),
  "KeyGenByClassName": KeyGenByClassName(),
  "KeyGenByClassSimpleName": KeyGenByClassSimpleName(),
};
