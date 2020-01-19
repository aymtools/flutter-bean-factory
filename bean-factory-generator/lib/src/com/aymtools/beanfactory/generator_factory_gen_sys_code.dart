import 'dart:io';

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
//    wUri = wUri.substring(0, wUri.lastIndexOf(".dart"));
//    wUri += ".sys.bf.aymtools.dart";
    String filePath = buildStep.inputId.path;
    filePath = filePath.substring(0, filePath.lastIndexOf("/"));
    filePath = "$filePath/beanfactory.sys.aymtools.dart";
    wUri = wUri.substring(0, wUri.lastIndexOf("/") + 1) +
        'beanfactory.sys.aymtools.dart';
    _genSysGenerator(wUri).then((value) {
      var sysBFFile = File(filePath);
      if (sysBFFile.existsSync()) {
        sysBFFile.deleteSync();
      }
      sysBFFile.writeAsString(
          BeanFactoryGenerator.writeDartFileFormatter.format(value));
    });
    return null;
  }

  Future<String> _genSysGenerator(String writeUri) async {
    String result = BeanFactoryGenerator.imports
        .where((i) => "dart:core" != i.key)
        .map((item) => "" == item.value
            ? "import '${item.key}';"
            : "import '${item.key}' as ${item.value} ;")
        .fold("", (i, n) => i + n);

    BeanFactoryGenerator.beanSysCreatorMap
        .addAll(BeanFactoryGenerator.beanMap.map((k, v) => MapEntry(
            k,
            GBeanCreator(
              v.uri,
              null,
              null,
              "${v.clsType}SysCreator",
              writeUri,
              BeanFactoryGenerator.parseAddImportList(
                      writeUri, BeanFactoryGenerator.imports)
                  .value,
            )))); //'BeanCreator'
    result = BeanFactoryGenerator.beanMap.values
        .map((b) => _genClassCreator(b))
        .fold(result, (i, n) => i + n);

    result = BeanFactoryGenerator.beanMap.values
//    .map((e){
//      print("${e.elementName}: ${e.methods.length} :");
//      return e;
//    })
        .where((e) => e.methods.isNotEmpty)
        .map((b) => _genMethodInvoke(b))
        .fold(result, (i, n) => i + n);
    result = BeanFactoryGenerator.beanMap.values
        .where((e) => e.fields.isNotEmpty)
        .map((b) => _genFieldGet(b))
        .fold(result, (i, n) => i + n);
    result = BeanFactoryGenerator.beanMap.values
        .where((e) => e.fields.isNotEmpty)
        .map((b) => _genFieldSet(b))
        .fold(result, (i, n) => i + n);
    result = BeanFactoryGenerator.beanMap.values
        .where((e) => e.fields.isNotEmpty)
        .map((b) => _genFieldGets(b))
        .fold(result, (i, n) => i + n);
    result = BeanFactoryGenerator.beanMap.values
        .where((e) => e.fields.isNotEmpty)
        .map((b) => _genFieldSets(b))
        .fold(result, (i, n) => i + n);
    return result;
  }

  String _genClassCreator(GBean gBean) {
    return """   
@BeanCreator("${gBean.uri}") 
class ${gBean.clsType}SysCreator extends BeanCustomCreatorBase<${gBean.clsType_}> {
  @override
  ${gBean.clsType_} create(
      String namedConstructorInUri, Map<String, dynamic> mapParam, objectParam) {
       ${BeanFactoryGenerator.beanCreatorBySysGenerator.generateBeanSwitchConstructorInstance(gBean, 'namedConstructorInUri', 'mapParam', 'objectParam')}
  }
}
    """;
  }

  String _genMethodInvoke(GBean gBean) {
    return """
dynamic invoke${gBean.clsType}Methods(${gBean.clsType_} bean , String methodName , {Map<String, dynamic> params}){
   ${BeanFactoryGenerator.beanCreatorBySysGenerator.generateBeanSwitchGBeanMethodInvoker(gBean, 'methodName', 'bean', 'params')}
    throw NoSuchMethodException(${gBean.clsType_} , methodName);
}
    """;
  }

  String _genFieldGet(GBean gBean) {
    return """
dynamic get${gBean.clsType}Fields(${gBean.clsType_} bean , String fieldName){
    switch (fieldName) {
        ${gBean.fields.map((e) => e.value).map((m) => "case '${m.fieldNameKey}' : return bean.${m.fieldName};").reduce((v, e) => v + e)}
    }
    throw NoSuchFieldException(${gBean.clsType_} , fieldName);
}
    """;
  }

  String _genFieldSet(GBean gBean) {
    return """
void set${gBean.clsType}Fields(${gBean.clsType_} bean , String fieldName , dynamic value){
    switch (fieldName) {
        ${gBean.fields.map((e) => e.value).map((m) => "case '${m.fieldNameKey}' : bean.${m.fieldName}=value; break;").reduce((v, e) => v + e)}
    }
    throw NoSuchFieldException(${gBean.clsType_} , fieldName);
}
    """;
  }

  String _genFieldGets(GBean gBean) {
    return """
Map<String,dynamic> get${gBean.clsType}AllFields(${gBean.clsType_} bean){
    Map<String,dynamic> result={};
    ${gBean.fields.map((e) => e.value).map((e) => "result['${e.fieldNameKey}']=bean.${e.fieldName};").reduce((v, e) => v + e)}
    return result;
}
    """;
  }

  String _genFieldSets(GBean gBean) {
    return """
void set${gBean.clsType}AllFields(${gBean.clsType_} bean , Map<String,dynamic> values){
    ${gBean.fields.map((e) => e.value).map((e) => "if (values.containsKey('${e.fieldNameKey}')) { set${gBean.clsType}Fields(bean,'${e.fieldNameKey}',values['${e.fieldNameKey}']); }").reduce((v, e) => v + e)}
}
    """;
  }
}
