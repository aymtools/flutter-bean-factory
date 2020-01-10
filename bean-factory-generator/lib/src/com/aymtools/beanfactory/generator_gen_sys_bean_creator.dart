import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'code_templates.dart';
import 'entities.dart';
import 'generator_factory.dart';

///自动将已注册的Bean 自动创建生成器，不在使用一堆代码来生成 各种使用各自的生成器来生成
class GenSysBeanCreatorGenerator extends GeneratorForAnnotation<Factory> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    String wUri = element.librarySource.uri.toString();
    wUri = wUri.substring(0, wUri.lastIndexOf(".dart"));
    wUri += ".sys.creator.bf.aymtools.dart";
    return _genSysGenerator(wUri);
  }

  Future<String> _genSysGenerator(String writeUri) async {
    String result = BeanFactoryGenerator.imports
        .where((i) => "dart:core" != i.key)
        .map((item) => "" == item.value
            ? "import '${item.key}';"
            : "import '${item.key}' as ${item.value} ;")
        .fold("", (i, n) => i + n);

    BeanFactoryGenerator.beanSysCreatorMap.addAll(BeanFactoryGenerator.beanMap
        .map((k, v) => MapEntry(
            k,
            GBeanCreator(
                v.uri,
                "${v.clsType}SysCreator",
                writeUri,
                BeanFactoryGenerator.parseAddImportList(
                        writeUri, BeanFactoryGenerator.imports)
                    .value,
                null,
                null)))); //'BeanCreator'
    result = BeanFactoryGenerator.beanMap.values
        .map((b) => _genSysClassGenerator(b))
        .fold(result, (i, n) => i + n);

    return result;
  }

  String _genSysClassGenerator(GBean gBean) {
    return """   
@BeanCreator("${gBean.uri}") 
class ${gBean.clsType}SysCreator extends BeanCustomCreatorBase<${gBean.clsType_}> {
  @override
  ${gBean.clsType_} create(
      String namedConstructorInUri, Map<String, dynamic> mapParam, objParam) {
      ${gBean.clsType_} beanInstance;
      ${BeanFactoryGenerator.beanCreatorBySysGenerator.generateBeanSwitchConstructorInstance(gBean)}
      return beanInstance;
  }
}
    """;
  }
}
