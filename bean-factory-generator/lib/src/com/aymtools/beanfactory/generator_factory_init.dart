import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator_factory.dart';

class BeanFactoryInitGenerator extends GeneratorForAnnotation<Factory> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (annotation != null &&
        annotation.peek('otherImports') != null &&
        annotation.peek('otherImports').listValue.isNotEmpty) {
      _parseOthersImportFactory(
          annotation.peek('otherImports').listValue, buildStep);
    }

//    if (annotation != null &&
//        annotation.peek('otherKeyGen') != null &&
//        annotation.peek('otherKeyGen').listValue.isNotEmpty) {
//      _parseCustomKeyGenFactory(
//          annotation.peek('otherKeyGen').listValue, buildStep);
//    }
    return null;
  }

  _parseOthersImportFactory(List<DartObject> listValue, BuildStep buildStep) {
    listValue.forEach((obj) =>
        BeanFactoryGenerator.imports.add(Pair(obj.toStringValue(), "")));
  }

//  _parseCustomKeyGenFactory(List<DartObject> listValue, BuildStep buildStep) {
//    listValue.forEach((obj) => print(obj.type));
//  }
}
