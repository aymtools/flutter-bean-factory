//import 'dart:io';
//
//import 'package:analyzer/dart/element/element.dart';
//import 'package:analyzer/dart/element/type.dart';
//import 'package:bean_factory/bean_factory.dart';
//import 'package:build/build.dart';
//import 'package:dart_style/dart_style.dart';
//import 'package:mustache4dart/mustache4dart.dart';
//import 'package:source_gen/source_gen.dart';
//
//import 'code_templates.dart';
//import 'constants.dart';
//import 'entities.dart';
//import 'generator_bean.dart';
//import 'generator_bean_creator.dart';
//
//class BeanFactoryGenerator extends GeneratorForAnnotation<Factory> {
//  static final writeDartFileFormatter = DartFormatter();
//
//  static final Map<String, GBean> beanMap = {};
//  static final Map<String, GBean> beanParseErrorMap = {};
//  static final Map<String, GBeanCreator> beanCreatorMap = {};
//  static final Map<String, GBeanCreator> beanSysCreatorMap = {};
//
//  ///导入包配置 把默认的包先增加进去
//  static final List<Pair<String, String>> imports = [
//    Pair("package:bean_factory/bean_factory.dart", "")
//  ];
//
//  static final GBeanCreatorBySysGenerator beanCreatorBySysGenerator =
//      GBeanCreatorBySysGenerator();
//  static final GBeanInstanceGenerator beanInstanceGenerator =
//      GBeanInstanceGenerator();
//
//  static final Map<String, KeyGen> keyGens = {
//    "KeyGenByUri": KeyGenByUri(),
//    "KeyGenBySequence": KeyGenBySequence(),
//    "KeyGenByClassName": KeyGenByClassName(),
//    "KeyGenByClassSimpleName": KeyGenByClassSimpleName(),
//  };
//  static final List<String> needScanPackage = [];
//  static String _beanFactoryDartFileUri = '', _beanFactorySysDartFileUri = '';
//
//  @override
//  generateForAnnotatedElement(
//      Element element, ConstantReader annotation, BuildStep buildStep) async {
//    await genBeanFactory(buildStep);
//    return null;
//  }
//
//  genBeanFactory(BuildStep buildStep) async {
//    if (beanCreatorMap.isEmpty && beanSysCreatorMap.isEmpty) return null;
//
//    _beanFactoryDartFileUri = _genBeanFactoryDartFileUri(buildStep);
//    _beanFactorySysDartFileUri = _genBeanFactorySysDartFileUri(buildStep);
//
//    String sysAs = getImportInfoDefN(getBeanFactorySysDartLibUri).value;
//
//    String bfContent = render(codeTemplate, <String, dynamic>{
//      'imports': imports
//          .map((item) => {
//                'importsPath': "" == item.value
//                    ? "import '${item.key}';"
//                    : "import '${item.key}' as ${item.value} ;"
//              })
//          .toList(),
//      'createBeanInstanceByCustomCreator': beanCreatorMap.entries.isEmpty
//          ? ''
//          : beanInstanceGenerator
//              .generateBeanSwitchInstance(beanCreatorMap.values

////              .where((gen) => !beanSysCreatorMap.containsKey(gen.uri))
//                  .toList()),
//      'createBeanInstanceBySysCreator': beanMap.entries.isEmpty
//          ? ''
//          : beanInstanceGenerator
//              .generateBeanSwitchInstance(beanSysCreatorMap.values.toList()),
//      'invokeMethods': beanMap.entries.isEmpty
//          ? ''
//          : beanMap.entries
//              .map((e) => e.value)
//              .where((e) => e.methods.isNotEmpty)
//              .map((e) =>
//                  'case ${e.clsType_} : return ${sysAs}.invoke${e.clsType}Methods(bean, methodName,    params: params);')
//              .fold('', (p, e) => p + e),
//      'getFields': beanMap.entries.isEmpty
//          ? ''
//          : beanMap.entries
//              .map((e) => e.value)
//              .where((e) => e.fields.isNotEmpty)
//              .map((e) =>
//                  'case ${e.clsType_} : return ${sysAs}.get${e.clsType}Fields(bean, fieldName);')
//              .fold('', (p, e) => p + e),
//      'setFields': beanMap.entries.isEmpty
//          ? ''
//          : beanMap.entries
//              .map((e) => e.value)
//              .where((e) => e.fields.isNotEmpty)
//              .map((e) =>
//                  'case ${e.clsType_} :  ${sysAs}.set${e.clsType}Fields(bean, fieldName, value);break;')
//              .fold('', (p, e) => p + e),
//      'getAllFields': beanMap.entries.isEmpty
//          ? ''
//          : beanMap.entries
//              .map((e) => e.value)
//              .where((e) => e.fields.isNotEmpty)
//              .map((e) =>
//                  'case ${e.clsType_} : return ${sysAs}.get${e.clsType}AllFields(bean);')
//              .fold('', (p, e) => p + e),
//      'setAllFields': beanMap.entries.isEmpty
//          ? ''
//          : beanMap.entries
//              .map((e) => e.value)
//              .where((e) => e.fields.isNotEmpty)
//              .map((e) =>
//                  'case ${e.clsType_} : ${sysAs}.set${e.clsType}AllFields(bean,values);break;')
//              .fold('', (p, e) => p + e),
//    });
//
//    String filePath = buildStep.inputId.path;
//    filePath = filePath.substring(0, filePath.lastIndexOf("/"));
//    filePath = "$filePath/beanfactory.aymtools.dart";
//    var sysBFFile = File(filePath);
//    if (sysBFFile.existsSync()) {
//      sysBFFile.deleteSync();
//    }
//    sysBFFile.writeAsString(writeDartFileFormatter.format(bfContent));
//
//    print(getScannedPackage());
//  }
//
//  String _genBeanFactoryDartFileUri(BuildStep buildStep) {
//    String wUri = buildStep.inputId.uri.toString();
////    wUri = wUri.substring(0, wUri.lastIndexOf(".dart"));
////    wUri += ".bf.aymtools.dart";
//    wUri = wUri.substring(0, wUri.lastIndexOf("/") + 1) +
//        'beanfactory.aymtools.dart';
//    return wUri;
//  }
//
//  String _genBeanFactorySysDartFileUri(BuildStep buildStep) {
//    String wUri = buildStep.inputId.uri.toString();
////    wUri = wUri.substring(0, wUri.lastIndexOf(".dart"));
////    wUri += ".sys.bf.aymtools.dart";
//    wUri = wUri.substring(0, wUri.lastIndexOf("/") + 1) +
//        'beanfactory.sys.aymtools.dart';
//    return wUri;
//  }
//
//  static Pair<String, String> parseAddImport(DartType type) {
//    return _parseImportList(type.element.librarySource.uri.toString(), imports);
//  }
//
//  static Pair<String, String> parseAAddImportList(
//      DartType type, List<Pair<String, String>> routeImports) {
//    String typeLibraryName = type.element.library.name;
//    if ("dart.core" == typeLibraryName || type.element.library.isDartCore) {
//      return Pair("", "");
//    }
//    return _parseImportList(
//        type.element.librarySource.uri.toString(), routeImports);
//  }
//
//  static Pair<String, String> parseAddImportList(
//      String sourceUriStr, List<Pair<String, String>> routeImports) {
//    return _parseImportList(sourceUriStr, routeImports);
//  }
//
//  static Pair<String, String> _parseImportList(
//      String uri, List<Pair<String, String>> routeImports) {
//    if ("" == uri || !uri.endsWith(".dart")) return Pair(uri, uri);
//    var impor = findFistWhere(routeImports, (imp) => uri == imp.key);
//    if (null == impor) {
//      String asStr = _formatAsStr(uri);
//      Pair<String, String> pair = Pair(uri, asStr);
//      routeImports.add(pair);
//      return pair;
//    } else
//      return impor;
//  }
//
//  static String _formatAsStr(String uri) {
//    if ("" == uri || !uri.endsWith(".dart")) return uri;
//    String asStr = uri
//        .substring(0, uri.length - 5)
//        .replaceAll("/", "_")
//        .replaceFirst("package:", "")
//        .replaceAllMapped(
//            RegExp(r"_\w"), (match) => match.group(0).toUpperCase())
//        .replaceAll("_", "");
//    if (asStr.indexOf(".") > -1) {
//      asStr = asStr
//          .replaceAllMapped(
//              RegExp(r"\.\w"), (match) => match.group(0).toUpperCase())
//          .replaceAll(".", "");
//    }
//    if (asStr.length > 1) {
//      asStr = asStr[0].toUpperCase() + asStr.substring(1);
//    }
//    int i = 0;
//    String asStrTemp = asStr;
//    while ((findFistWhere(
//            BeanFactoryGenerator.imports, (imp) => asStrTemp == imp.value)) !=
//        null) {
//      i++;
//      asStrTemp = '${asStr}_$i';
//    }
//    return asStrTemp;
//  }
//
//  static Pair<String, String> getImportInfo(String uri,
//          {Pair<String, String> orElse()}) =>
//      imports.firstWhere((p) => p.key == uri, orElse: orElse);
//
//  static Pair<String, String> getImportInfoDefN(String uri) =>
//      getImportInfo(uri, orElse: () => Pair('', ''));
//
//  static String getBeanFactoryDartLibUri = _beanFactoryDartFileUri;
//
//  static String getBeanFactorySysDartLibUri = _beanFactorySysDartFileUri;
//
//  static List<GBean> getGBeans(bool test(GBean bean)) =>
//      beanMap.values.where(test);
//
//  static List<GBean> getGBeansForAnnotation(Type annotationType) {
//    TypeChecker checker = TypeChecker.fromRuntime(annotationType);
//    return getGBeans((bean) => bean.annotation.instanceOf(checker));
//  }
//
//  static GBean getGBeanForClassElement(Element element) {
//    if (element.kind != ElementKind.CLASS) return null;
//    return getGBeanForDartFile(
//        element.librarySource.uri.toString(), element.name);
//  }
//
//  static GBean getGBeanForDartFile(String librarySourceUri, String className) {
////    return getGBeans((bean) =>
////            bean.sourceUri == librarySourceUri && bean.typeName == className)
////        ?.first;
//    if (_tempQuickSearch.isEmpty) {
//      beanMap.values.forEach((e) {
//        Map<String, GBean> map = _tempQuickSearch[e.type.typeLibSourceUri];
//        if (map == null) {
//          map = {};
//          _tempQuickSearch[e.type.typeLibSourceUri] = map;
//        }
//        map[e.type.typeName] = e;
//      });
//    }
//    return _tempQuickSearch[librarySourceUri][className];
//  }
//
//  static Map<String, Map<String, GBean>> _tempQuickSearch = {};
//}

import 'package:bean_factory_generator/src/com/aymtools/beanfactory/constants.dart'
    as bf;
import 'package:bean_factory_generator/bean_factory_generator.dart';

import 'builder.dart';

class BeanFactoryGenerator {
  static Map<String, GBean> get beanMap => bf.beanMap;

  static Map<String, GBeanCreator> get beanCreatorMap => bf.beanCreatorMap;

  static String get beanFactoryDartLibUri => bf.beanFactoryCodeUri;

  static String get beanFactorySysDartLibUri => bf.beanFactoryInvokerCodeUri;

  static String getBeanFactoryDartLibUri() => beanFactoryDartLibUri;

  static String getBeanFactorySysDartLibUri() => beanFactorySysDartLibUri;

  static Map<String, String> get imports => bf.imports;
}

class BeanFactory {
  static Map<String, GBean> get beanMap => bf.beanMap;

  static Map<String, GBeanCreator> get beanCreatorMap => bf.beanCreatorMap;

  static String get beanFactoryDartLibUri => bf.beanFactoryCodeUri;

  static String get beanFactorySysDartLibUri => bf.beanFactoryInvokerCodeUri;

  static Map<String, String> get imports => bf.imports;

  static bool get isGenerated => bf.config != null && Gen.isGenerated;
}
