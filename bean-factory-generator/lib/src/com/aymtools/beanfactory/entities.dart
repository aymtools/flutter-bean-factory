import 'package:bean_factory/bean_factory.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory_generator/bean_factory_generator.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/constants.dart';
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
  GType _extType;

  GType get extType {
    if (_extType != null) return _extType;
    if (annotation.isNull ||
        annotation.peek('extType').isNull ||
        !annotation.peek('extType').isType) {
      return null;
    }
    DartType type = annotation.peek('extType').typeValue;
    MapEntry<String, String> imp = parseAddImport(type);
    _extType = GType(type.element.displayName, imp.key, imp.value, type);
    return _extType;
  }

  List<GType> _extTypeList;

  List<GType> get extTypeList {
    if (_extType != null) return _extTypeList;
    if (annotation.isNull ||
        annotation.peek('extTypeList').isNull ||
        !annotation.peek('extTypeList').isList) {
      return [];
    }
    _extTypeList = annotation
        .peek('extTypeList')
        .listValue
        .map((e) => e.toTypeValue())
        .map((e) {
      MapEntry<String, String> imp = parseAddImport(e);
      return GType(e.element.displayName, imp.key, imp.value, e);
    }).toList();

    return _extTypeList;
  }
}

class GType {
  final String _typeName;
  final String typeLibSourceUri;
  final String typeLibSourceAsStr;
  final DartType dartType;
  final List<GType> typeArguments;

  GType(this._typeName, this.typeLibSourceUri, this.typeLibSourceAsStr,
      this.dartType)
      : typeArguments = dartType != null && dartType is ParameterizedType
            ? dartType.typeArguments
                .map((e) => e.isDynamic
                    ? GType('dynamic', '', '', e)
                    : GType(
                        e.element.displayName,
                        e.element.librarySource?.uri?.toString() ?? '',
                        parseAddImport(e).value,
                        e))
                .toList()
            : [];

  bool get isDartCoreBool => dartType.isDartCoreBool;

  bool get isDartCoreDouble => dartType.isDartCoreDouble;

  bool get isDartCoreInt => dartType.isDartCoreInt;

  bool get isTypeDartCoreBase =>
      isDartCoreBool || isDartCoreDouble || isDartCoreInt;

  bool get isTypeDartCoreString => dartType.isDartCoreString;

  String get typeAsStrName =>
      '' == typeLibSourceAsStr ? _TName : "${typeLibSourceAsStr}.${_TName}";

  String get _TName => typeArguments.length == 0
      ? _typeName
      : '${dartType.element.displayName}<${typeArguments.map((e) => e.typeAsStrName).reduce((v, e) => '$v,$e')}>';
}

class GBeanParam extends _Tag {
  final ParameterElement parameterElement;

  final bool isNamed;

  final GType type;

  GBeanParam(
    this.parameterElement,
    ConstantReader annotation,
    this.isNamed,
    String typeLibSourceUri,
    String typeLibSourceAsStr,
    String typeName,
    DartType dartType,
  )   : this.type =
            GType(typeName, typeLibSourceUri, typeLibSourceAsStr, dartType),
        super(parameterElement, annotation);

  String get paramName => elementName;

  bool get isTypeDartCoreBase =>
      type.dartType.isDartCoreBool ||
      type.dartType.isDartCoreDouble ||
      type.dartType.isDartCoreInt;

  bool get isTypeDartCoreString => type.dartType.isDartCoreString;

  bool get isTypeDartCoreMap =>type.dartType.isDartCoreMap;
//      "" == type.typeLibSourceAsStr &&
//      "Map" == type.dartType.element.displayName;

  String get paramType => type.typeAsStrName;

  String get paramTypeNoParamInfo => "" == type.typeLibSourceAsStr
      ? type.dartType.element.displayName
      : "${type.typeLibSourceAsStr}.${type.dartType.element.displayName}";

  String get keyInMaps => "" == key ? paramName : key;
}

class GBean extends _Tag {
  final String uri;

  final ClassElement classElement;

  final GType type;

  final List<Pair<String, GBeanConstructor>> constructors;
  final List<Pair<String, GBeanMethod>> methods;
  final List<Pair<String, GBeanField>> fields;

  GBean(
      this.uri,
      this.classElement,
      ConstantReader annotation,
      String typeName,
      String typeLibSourceUri,
      String typeLibSourceAsStr,
      DartType dartType,
      List<Pair<String, GBeanConstructor>> constructors,
      List<Pair<String, GBeanField>> fields,
      List<Pair<String, GBeanMethod>> methods)
      : this.type =
            GType(typeName, typeLibSourceUri, typeLibSourceAsStr, dartType),
        this.constructors = constructors ?? [],
        this.fields = fields ?? [],
        this.methods = methods ?? [],
        super(classElement, annotation);

  String get clsType => "" == type.typeLibSourceAsStr
      ? type.dartType.element.displayName
      : "${type.typeLibSourceAsStr}${type.dartType.element.displayName}";

  String get clsType_ => type.typeAsStrName;

  String get genByAnnotation => annotation.objectValue.type.getDisplayString();

  String get sourceUri => type.typeLibSourceUri;

  String get typeAsStr => type.typeLibSourceAsStr;

  bool isForAnnotation(TypeChecker checkerAnnotation) =>
      annotation != null && annotation.instanceOf(checkerAnnotation);

  bool isAssignableFrom(TypeChecker checker) =>
      element != null && checker.isAssignableFrom(element);

  GBeanConstructor getConstructor({String key, TypeChecker checkerAnnotation}) {
    if (key == null && checkerAnnotation == null)
      return null;
    else if (key != null && checkerAnnotation == null) {
      return constructors
          .firstWhere((e) => key == e.value.constructorNamedKey)
          ?.value;
    } else if (key == null && checkerAnnotation != null) {
      return constructors
          .firstWhere((e) =>
              e.value.annotation != null &&
              e.value.annotation.instanceOf(checkerAnnotation))
          ?.value;
    } else {
      GBeanConstructor field = constructors
          .firstWhere((e) => key == e.value.constructorNamedKey)
          ?.value;

      return field != null &&
              field.annotation != null &&
              field.annotation.instanceOf(checkerAnnotation)
          ? field
          : null;
    }
  }

  ///获取那个特别类型的构造函数
  GBeanConstructor getConstructorFor2Params() {
    return constructors
        .firstWhere((element) => element.value.isFor2Params, orElse: () => null)
        ?.value;
  }

  List<GBeanMethod> searchMethod({String key, TypeChecker checkerAnnotation}) =>
      methods
          .where((e) => key == null || key == e.value.methodNameKey)
          .where((e) =>
              checkerAnnotation == null ||
              (e.value.annotation != null &&
                  e.value.annotation.instanceOf(checkerAnnotation)))
          .map((e) => e.value)
          .toList();

  GBeanMethod searchFirstMethod({String key, TypeChecker checkerAnnotation}) {
    if (key == null && checkerAnnotation == null)
      return methods.isEmpty ? null : methods.first.value;
    else if (key != null && checkerAnnotation == null) {
      return methods.firstWhere((e) => key == e.value.methodNameKey)?.value;
    } else if (key == null && checkerAnnotation != null) {
      return methods
          .firstWhere((e) =>
              e.value.annotation != null &&
              e.value.annotation.instanceOf(checkerAnnotation))
          ?.value;
    } else
      return methods
          .firstWhere((e) =>
              key == e.value.methodNameKey &&
              e.value.annotation != null &&
              e.value.annotation.instanceOf(checkerAnnotation))
          ?.value;
  }

  List<GBeanField> getFields(TypeChecker checkerAnnotation) {
    return fields
        .where((e) =>
            e.value.annotation != null &&
            e.value.annotation.instanceOf(checkerAnnotation))
        .map((e) => e.value)
        .toList();
  }

  GBeanField getField({String key, TypeChecker checkerAnnotation}) {
    if (key == null && checkerAnnotation == null)
      return null;
    else if (key != null && checkerAnnotation == null) {
      return fields.firstWhere((e) => key == e.value.fieldNameKey)?.value;
    } else if (key == null && checkerAnnotation != null) {
      return fields
          .firstWhere((e) =>
              e.value.annotation != null &&
              e.value.annotation.instanceOf(checkerAnnotation))
          ?.value;
    } else {
      GBeanField field =
          fields.firstWhere((e) => key == e.value.fieldNameKey)?.value;

      return field != null &&
              field.annotation != null &&
              field.annotation.instanceOf(checkerAnnotation)
          ? field
          : null;
    }
  }
}

class GBeanConstructor extends _Tag {
  static final TypeChecker _typeCheckerConstructorFor2Params =
      TypeChecker.fromRuntime(BeanConstructorFor2Params);

  final String namedConstructorInUri;
  final ConstructorElement constructorElement;
  final ConstantReader annotation;

  final List<Pair<String, GBeanParam>> params;

  GBeanConstructor(this.namedConstructorInUri, this.constructorElement,
      this.annotation, List<Pair<String, GBeanParam>> params)
      : this.params = params ?? [],
        super(constructorElement, annotation);

  String get namedConstructor => elementName;

  String get constructorNamedKey => key.isEmpty ? namedConstructor : key;

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

  bool _isFor2Params;

  bool get isFor2Params {
    if (_isFor2Params == null) {
      _isFor2Params = params.length == 2 &&
          params[0].value.type.dartType.isDynamic &&
          params[1].value.type.dartType.isDartCoreMap &&
          annotation != null &&
          annotation.instanceOf(_typeCheckerConstructorFor2Params);
    }
    return _isFor2Params;
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

  GBeanMethod(this.methodElement, this.annotation,
      List<Pair<String, GBeanParam>> params)
      : this.params = params ?? [],
        super(methodElement, annotation);

  String get methodName => elementName;

  String get methodNameKey => key.isEmpty ? methodName : key;

  DartType get methodResultType => methodElement.returnType;

  bool get isResultVoid => methodResultType.isVoid;
//  bool get resultTypeName => methodResultType.name;
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

  final GType type;

  GBeanField(
    this.fieldElement,
    this.annotation,
    String typeLibSourceUri,
    String typeLibSourceAsStr,
    String typeName,
    DartType dartType,
  )   : this.type =
            GType(typeName, typeLibSourceUri, typeLibSourceAsStr, dartType),
        super(fieldElement, annotation);

  String get fieldName => elementName;

  String get fieldNameKey => key.isEmpty ? fieldName : key;

  bool get isStatic => fieldElement.isStatic;

  String get fieldType => type.typeAsStrName;
}

class GBeanCreator {
  final String uri;

  final ClassElement element;
  final ConstantReader annotation;

  final GType type;

  String get genByAnnotation => annotation.objectValue.type.getDisplayString();

  GBeanCreator(
    this.uri,
    this.element,
    this.annotation,
    String typeName,
    String typeLibSourceUri,
    String typeLibSourceAsStr,
    DartType dartType,
  ) : this.type =
            GType(typeName, typeLibSourceUri, typeLibSourceAsStr, dartType);

//  String get classNameCode => '' == type.typeLibSourceAsStr
//      ? type.typeName
//      : "${type.typeLibSourceAsStr}${type.typeName}";
  String get classNameCode => '' == type.typeLibSourceAsStr
      ? type.dartType.element.displayName
      : "${type.typeLibSourceAsStr}${type.dartType.element.displayName}";

  String get instantiateCode => type.typeAsStrName;
}
