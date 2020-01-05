import 'package:bean_factory/bean_factory.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class GBean {
  final String uri;
  final String typeName;
  final String sourceUri;
  final String typeAsStr;

  final String tag;
  final int ext;

  final ClassElement element;
  final ConstantReader annotation;

  String get clsType => "" == typeAsStr ? typeName : "${typeAsStr}${typeName}";

  String get clsType_ =>
      "" == typeAsStr ? typeName : "${typeAsStr}.${typeName}";

  String get genByAnnotation => annotation.objectValue.type.name;

  List<Pair<String, GBeanConstructor>> constructors = [];

  GBean(this.uri, this.typeName, this.sourceUri, this.typeAsStr, this.tag,
      this.ext, this.element, this.annotation);
}

class GBeanConstructor {
  String namedConstructorInRouter;
  String namedConstructorInEntity;

  GBeanConstructor(
      this.namedConstructorInRouter, this.namedConstructorInEntity);

  List<Pair<String, GBeanCreateParam>> params = [];

  String get namedConstructor => namedConstructorInRouter == ""
      ? namedConstructorInEntity
      : namedConstructorInRouter;

  bool get canCreateForNoParams {
    if (params.length == 0) return true;
    if (params.where((p) => !p.value.isNamed).length == 0) return true;
    return false;
  }

  bool get canCreateForOneParam {
    if (params.length == 1) return true;
    if (params.where((p) => !p.value.isNamed).length == 1) return true;
    return false;
  }
}

class GBeanCreateParam {
  String keyInMap;
  String keyInFun;
  bool isNamed;

  String typeName;
  String typeAsStr;
  String typeSourceUri;

  DartType type;
  Type runtimeType;

  GBeanCreateParam(
      this.keyInMap,
      this.keyInFun,
      this.isNamed,
      this.typeSourceUri,
      this.typeAsStr,
      this.typeName,
      this.type,
      this.runtimeType);

  bool get isTypeDartCoreBase =>
      type.isDartCoreBool || type.isDartCoreDouble || type.isDartCoreInt;

  bool get isTypeDartCoreString => type.isDartCoreString;

  bool get isTypeDartCoreMap => "" == typeAsStr && "Map" == typeName;

  String get paramType =>
      "" == typeAsStr ? typeName : "${typeAsStr}.${typeName}";

  String get key => "" == keyInMap ? keyInFun : keyInMap;
}

class GBeanCreator {
  final String uri;
  final String typeName;
  final String sourceUri;
  final String typeAsStr;

  final ClassElement element;
  final ConstantReader annotation;

  String get genByAnnotation => annotation.objectValue.type.name;

//  final String tag;
//  final int ext;

  GBeanCreator(
    this.uri,
    this.typeName,
    this.sourceUri,
    this.typeAsStr,
//      this.tag, this.ext
    this.element,
    this.annotation,
  );
}
