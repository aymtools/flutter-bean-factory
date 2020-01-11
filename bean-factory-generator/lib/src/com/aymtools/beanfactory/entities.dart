import 'package:bean_factory/bean_factory.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class _Tag {
  final Element element;
  final ConstantReader annotation;

  _Tag(this.element, this.annotation);

  String _key = null;

  String get elementName => element == null ? '' : element.name;

  String get key => _key != null
      ? _key
      : _key = annotation.isNull ||
              annotation.peek('key').isNull ||
              annotation.peek('key').stringValue.isEmpty
          ? ''
          : annotation.peek('key').stringValue;

  String _tag = null;

  String get tag => _tag != null
      ? _tag
      : _tag = annotation.isNull ||
              annotation.peek('tag').isNull ||
              annotation.peek('tag').stringValue.isEmpty
          ? ''
          : annotation.peek('tag').stringValue;

  int _ext = null;

  int get ext => _ext != null
      ? _ext
      : annotation.isNull || annotation.peek('ext').isNull
          ? -1
          : annotation.peek('ext').intValue;

  int _flag = null;

  int get flag => _flag != null
      ? _flag
      : annotation.isNull || annotation.peek('flag').isNull
          ? false
          : annotation.peek('flag').boolValue;

  String _tag1 = null;

  String get tag1 => _tag1 != null
      ? _tag1
      : _tag1 = annotation.isNull ||
              annotation.peek('tag1').isNull ||
              annotation.peek('tag1').stringValue.isEmpty
          ? ''
          : annotation.peek('tag1').stringValue;

  int _ext1 = null;

  int get ext1 => _ext1 != null
      ? _ext1
      : annotation.isNull || annotation.peek('ext1').isNull
          ? -1
          : annotation.peek('ext1').intValue;

  int _flag1 = null;

  int get flag1 => _flag1 != null
      ? _flag1
      : annotation.isNull || annotation.peek('flag1').isNull
          ? false
          : annotation.peek('flag1').boolValue;

  List<String> _tagList = null;

  List<String> get tagList => _tagList != null
      ? _tagList
      : _tagList = annotation.isNull ||
              annotation.peek('tagList').isNull ||
              annotation.peek('tagList').listValue.isEmpty
          ? []
          : annotation
              .peek('tagList')
              .listValue
              .map((e) => e.toStringValue())
              .toList();

  List<int> _extList = null;

  List<int> get extList => _extList != null
      ? _extList
      : _extList = annotation.isNull ||
              annotation.peek('extList').isNull ||
              annotation.peek('extList').listValue.isEmpty
          ? []
          : annotation
              .peek('extList')
              .listValue
              .map((e) => e.toIntValue())
              .toList();
}

class GBeanParam extends _Tag {
  final ParameterElement parameterElement;

  final bool isNamed;

  final String typeName;
  final String typeAsStr;
  final String typeSourceUri;

  final DartType type;
  final Type runtimeType;

  GBeanParam(
      this.parameterElement,
      ConstantReader annotation,
      this.isNamed,
      this.typeSourceUri,
      this.typeAsStr,
      this.typeName,
      this.type,
      this.runtimeType)
      : super(parameterElement, annotation);

  String get paramName => elementName;

  bool get isTypeDartCoreBase =>
      type.isDartCoreBool || type.isDartCoreDouble || type.isDartCoreInt;

  bool get isTypeDartCoreString => type.isDartCoreString;

  bool get isTypeDartCoreMap => "" == typeAsStr && "Map" == typeName;

  String get paramType =>
      "" == typeAsStr ? typeName : "${typeAsStr}.${typeName}";

  String get keyInMaps => "" == key ? paramName : key;
}

class GBean extends _Tag {
  final String uri;

  final ClassElement classElement;

  final String typeName;
  final String sourceUri;
  final String typeAsStr;

  final List<Pair<String, GBeanConstructor>> constructors;
  final List<Pair<String, GBeanMethod>> methods;
  final List<Pair<String, GBeanField>> fields;

  GBean(
      this.uri,
      this.classElement,
      ConstantReader annotation,
      this.typeName,
      this.sourceUri,
      this.typeAsStr,
      this.constructors,
      this.fields,
      this.methods)
      : super(classElement, annotation);

  String get clsType => "" == typeAsStr ? typeName : "${typeAsStr}${typeName}";

  String get clsType_ =>
      "" == typeAsStr ? typeName : "${typeAsStr}.${typeName}";

  String get genByAnnotation => annotation.objectValue.type.name;
}

class GBeanConstructor extends _Tag {
  final String namedConstructorInUri;
  final ConstructorElement constructorElement;
  final ConstantReader annotation;

  final List<Pair<String, GBeanParam>> params;

  GBeanConstructor(this.namedConstructorInUri, this.constructorElement,
      this.annotation, this.params)
      : super(constructorElement, annotation);

  String get namedConstructor => elementName;

//  String get namedConstructorInUri => key == "" ? namedConstructor : key;

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

//class GBeanCreateParam extends GBeanParam {
//  GBeanCreateParam(
//      ParameterElement element,
//      ConstantReader annotation,
//      bool isNamed,
//      String typeSourceUri,
//      String typeAsStr,
//      String typeName,
//      DartType type,
//      Type runtimeType)
//      : super(element, annotation, isNamed, typeSourceUri, typeAsStr, typeName,
//            type, runtimeType);
//}

class GBeanMethod extends _Tag {
  final MethodElement methodElement;
  final ConstantReader annotation;

  final List<Pair<String, GBeanParam>> params;

  GBeanMethod(this.methodElement, this.annotation, this.params)
      : super(methodElement, annotation);

  String get methodName => elementName;
}

//class GBeanMethodParam extends GBeanParam {
//  GBeanMethodParam(
//      ParameterElement element,
//      ConstantReader annotation,
//      bool isNamed,
//      String typeSourceUri,
//      String typeAsStr,
//      String typeName,
//      DartType type,
//      Type runtimeType)
//      : super(element, annotation, isNamed, typeSourceUri, typeAsStr, typeName,
//            type, runtimeType);
//}

class GBeanField extends _Tag {
  final FieldElement fieldElement;
  final ConstantReader annotation;

  final String typeName;
  final String typeAsStr;
  final String typeSourceUri;

  final DartType type;
  final Type runtimeType;

  GBeanField(this.fieldElement, this.annotation, this.typeSourceUri,
      this.typeAsStr, this.typeName, this.type, this.runtimeType)
      : super(fieldElement, annotation);

  String get fieldName => elementName;
}

class GBeanCreator {
  final String uri;

  final ClassElement element;
  final ConstantReader annotation;

  final String typeName;
  final String sourceUri;
  final String typeAsStr;

  String get genByAnnotation => annotation.objectValue.type.name;

  GBeanCreator(
    this.uri,
    this.element,
    this.annotation,
    this.typeName,
    this.sourceUri,
    this.typeAsStr,
  );
}
