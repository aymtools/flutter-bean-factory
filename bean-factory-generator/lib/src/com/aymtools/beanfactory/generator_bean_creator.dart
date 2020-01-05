import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';

import 'entities.dart';
import 'generator_factory.dart';

import 'package:analyzer/dart/element/type.dart';

class ScanBeanCreatorGenerator extends GeneratorForAnnotation<BeanCreator> {
  TypeChecker _customCreatorChecker =
      TypeChecker.fromRuntime(BeanCustomCreatorBase);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    _parseGBeanCreatorMap(
        BeanFactoryGenerator.beanCreatorMap, element, annotation);
    return null;
  }

  _parseGBeanCreatorMap(Map<String, GBeanCreator> routePageGeneratorMap,
      Element element, ConstantReader annotation) {
    if (element.kind != ElementKind.CLASS) return routePageGeneratorMap;

    if (!_customCreatorChecker.isAssignableFrom(element))
      return routePageGeneratorMap;

    String clazz = element.displayName;
    String uri = annotation.peek('uri').stringValue;

    String uriKey = "'" + uri + "'";
    Pair<String, String> imp = BeanFactoryGenerator.parseAddImportList(
        element.librarySource.uri.toString(), BeanFactoryGenerator.imports);
    GBeanCreator pageGenerator = new GBeanCreator(
        uri, clazz, imp.key, imp.value, (element as ClassElement), annotation);

    if (!uri.endsWith(".sys.creator.bf.aymtools.dart")) {
      if (!routePageGeneratorMap.containsKey(uriKey)) {
        routePageGeneratorMap[uri] = pageGenerator;
      }
    }
    return routePageGeneratorMap;
  }
}

class GBeanInstanceGenerator {
  String generateBeanSwitchInstance(List<GBeanCreator> routeMap) {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln(" switch (uri) {");
    routeMap.forEach((GBeanCreator generator) {
      stringBuffer.writeln('case "${generator.uri}" :');
      stringBuffer.writeln(
          ' return ${generator.typeAsStr}.${generator.typeName}().create(namedConstructorInRouter,mapParam,objParam);');
    });
    stringBuffer.writeln("default: return null;}");
    return stringBuffer.toString();
  }
}