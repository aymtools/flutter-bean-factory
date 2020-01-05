import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/build.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/type.dart';

import 'entities.dart';
import 'code_templates.dart';
import 'generator_bean.dart';
import 'generator_bean_creator.dart';

class BeanFactoryGenerator extends GeneratorForAnnotation<Factory> {
  static Map<String, GBean> beanMap = {};
  static Map<String, GBean> beanParseErrorMap = {};
  static Map<String, GBeanCreator> beanCreatorMap = {};
  static Map<String, GBeanCreator> beanSysCreatorMap = {};

  ///导入包配置 把默认的包先增加进去
  static List<Pair<String, String>> imports = [
    Pair("package:bean_factory/bean_factory.dart", "")
  ];

  static GBeanCreatorBySysGenerator beanCreatorBySysGenerator =
      GBeanCreatorBySysGenerator();
  static GBeanInstanceGenerator beanInstanceGenerator =
      GBeanInstanceGenerator();

  static Map<String, KeyGen> keyGens = {
    "KeyGenByUri": KeyGenByUri(),
    "KeyGenBySequence": KeyGenBySequence(),
    "KeyGenByClassName": KeyGenByClassName(),
    "KeyGenByClassSimpleName": KeyGenByClassSimpleName(),
  };

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return render(codeTemplate, <String, dynamic>{
      'imports': imports
          .map((item) => {
                'importsPath': "" == item.value
                    ? "import '${item.key}';"
                    : "import '${item.key}' as ${item.value} ;"
              })
          .toList(),
      'createBeanInstanceByCustomCreator':
          beanInstanceGenerator.generateBeanSwitchInstance(beanCreatorMap.values
//              .where((gen) => !beanSysCreatorMap.containsKey(gen.uri))
              .toList()),
      'createBeanInstanceBySysCreator': beanInstanceGenerator
          .generateBeanSwitchInstance(beanSysCreatorMap.values.toList()),
    });
  }

  static Pair<String, String> parseAAddImportList(
      DartType type, List<Pair<String, String>> routeImports) {
    String typeLibraryName = type.element.library.name;
    if ("dart.core" == typeLibraryName || type.element.library.isDartCore)
      return Pair("", "");
    return _parseImportList(
        type.element.librarySource.uri.toString(), routeImports);
  }

  static Pair<String, String> parseAddImportList(
      String sourceUriStr, List<Pair<String, String>> routeImports) {
    return _parseImportList(sourceUriStr, routeImports);
  }

  static Pair<String, String> _parseImportList(
      String uri, List<Pair<String, String>> routeImports) {
    if ("" == uri || !uri.endsWith(".dart")) return new Pair(uri, uri);
    var impor = findFistWhere(routeImports, (imp) => uri == imp.key);
    if (null == impor) {
      String asStr = _formatAsStr(uri);
      Pair<String, String> pair = new Pair(uri, asStr);
      routeImports.add(pair);
      return pair;
    } else
      return impor;
  }

  static String _formatAsStr(String uri) {
    if ("" == uri || !uri.endsWith(".dart")) return uri;
    String asStr = uri
        .substring(0, uri.length - 5)
        .replaceAll("/", "_")
        .replaceFirst("package:", "")
        .replaceAllMapped(
            new RegExp(r"_\w"), (match) => match.group(0).toUpperCase())
        .replaceAll("_", "");
    if (asStr.indexOf(".") > -1) {
      asStr = asStr
          .replaceAllMapped(
              new RegExp(r"\.\w"), (match) => match.group(0).toUpperCase())
          .replaceAll(".", "");
    }
    if (asStr.length > 1) {
      asStr = asStr[0].toUpperCase() + asStr.substring(1);
    }
    int i = 0;
    String asStrTemp = asStr;
    while ((findFistWhere(
            BeanFactoryGenerator.imports, (imp) => asStrTemp == imp.value)) !=
        null) {
      i++;
      asStrTemp = '${asStr}_$i';
    }
    return asStrTemp;
  }

  static Pair<String, String> getImportInfo(String uri) =>
      imports.firstWhere((p) => p.key == uri);
}
