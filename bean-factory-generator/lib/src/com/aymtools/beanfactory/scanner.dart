import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:bean_factory_generator/bean_factory_generator.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/constants.dart';
import 'package:source_gen/source_gen.dart';

TypeChecker _beanChecker = TypeChecker.fromRuntime(Bean);
TypeChecker _beanCreatorChecker = TypeChecker.fromRuntime(BeanCreator);

scan(LibraryReader library) {
  print('scan lib ${library.element.librarySource.uri}');
  library
      .annotatedWith(_beanChecker)
      .forEach((element) => _scanBean(element.element, element.annotation));
  library.annotatedWith(_beanCreatorChecker).forEach(
      (element) => _scanBeanCreator(element.element, element.annotation));
}

TypeChecker _beanConstructorAnnotation =
    TypeChecker.fromRuntime(BeanConstructor);
TypeChecker _beanConstructorNotAnnotation =
    TypeChecker.fromRuntime(BeanConstructorNot);
TypeChecker _beanParamAnnotation = TypeChecker.fromRuntime(BeanParam);

TypeChecker _beanMethodAnnotation = TypeChecker.fromRuntime(BeanMethod);
TypeChecker _beanMethodNotAnnotation = TypeChecker.fromRuntime(BeanMethodNot);

TypeChecker _beanFieldAnnotation = TypeChecker.fromRuntime(BeanField);
TypeChecker _beanFieldNotAnnotation = TypeChecker.fromRuntime(BeanFieldNot);

void _scanBean(Element element, ConstantReader annotation) {
  if (element.kind != ElementKind.CLASS) return;
  ConstantReader from = annotation.peek("needAssignableFrom");
  if (!from.isNull &&
      from.isList &&
      from.listValue.isNotEmpty &&
      !from.listValue
          .map((e) => e.toTypeValue())
          .every((c) => TypeChecker.fromStatic(c).isAssignableFrom(element)))
    return;

  String clazz = element.displayName;
  String key =
      annotation.peek('key').isNull ? '' : annotation.peek('key').stringValue;

  String tag =
      annotation.peek('tag').isNull ? '' : annotation.peek('tag').stringValue;
  int ext =
      annotation.peek('ext').isNull ? -1 : annotation.peek('ext').intValue;

  KeyGen keyGen = KeyGenByClassName();
  if (!(annotation.peek('keyGen').isNull ||
      annotation.peek('keyGen').objectValue.isNull ||
      '' == annotation.peek('keyGen').objectValue.type.getDisplayString())) {
//    print(
//        'keyGen:${annotation.peek('keyGen').objectValue.type.getDisplayString()}');
    keyGen =
        keyGens[annotation.peek('keyGen').objectValue.type.getDisplayString()];
  }
  if (keyGen == null) {
    keyGen = KeyGenByClassName();
  }
  String sourceUri = element.librarySource.uri.toString();
  String uriKey = keyGen.gen(key, tag, ext, clazz, sourceUri);
  if ("" == uriKey)
    uriKey = KeyGenByClassName().gen(key, tag, ext, clazz, sourceUri);

  if (beanMap.containsKey(uriKey)) {
    return;
  }
  ClassElement e = (element as ClassElement);
  bool scanConstructors = !annotation.peek('scanConstructors').isNull &&
      annotation.peek('scanConstructors').boolValue;

  bool scanConstructorsUsedBlackList =
      annotation.peek('scanConstructorsUsedBlackList').isNull
          ? true
          : annotation.peek('scanConstructorsUsedBlackList').boolValue;

  bool scanFields = !annotation.peek('scanFields').isNull &&
      annotation.peek('scanFields').boolValue;
  bool scanFieldsUsedBlackList =
      !annotation.peek('scanFieldsUsedBlackList').isNull &&
          annotation.peek('scanFieldsUsedBlackList').boolValue;
  bool scanSuperFields = !annotation.peek('scanSuperFields').isNull &&
      annotation.peek('scanSuperFields').boolValue;

  bool scanMethods = !annotation.peek('scanMethods').isNull &&
      annotation.peek('scanMethods').boolValue;
  bool scanMethodsUsedBlackList =
      !annotation.peek('scanMethodsUsedBlackList').isNull &&
          annotation.peek('scanMethodsUsedBlackList').boolValue;
  bool scanSuperMethods = !annotation.peek('scanSuperMethods').isNull &&
      annotation.peek('scanSuperMethods').boolValue;
  GBean rp = GBean(
    uriKey,
    e,
    annotation,
    clazz,
    sourceUri,
    parseAddImports(sourceUri).value,
    e.thisType,
    scanConstructors
        ? _parseGBeanConstructors(e, !scanConstructorsUsedBlackList)
            .map((e) => Pair(e.namedConstructorInUri, e))
            .toList()
        : [
            Pair(
                '',
                e.constructors
                    .where((e) => '' == e.name)
                    .map(
                      (e) => GBeanConstructor(
                          '',
                          e,
                          ConstantReader(
                              _beanConstructorAnnotation.firstAnnotationOf(e)),
                          _parseGBeanFunctionParams(e.parameters)),
                    )
                    .firstWhere((e) => '' == e.key))
          ],
    scanFields || scanSuperFields
        ? _parseGBeanFields(e, scanSuperFields, !scanFieldsUsedBlackList)
        : [],
    scanMethods || scanSuperMethods
        ? _parseGBeanMethods(e, scanSuperMethods, !scanMethodsUsedBlackList)
        : [],
  );

  if (rp.constructors.length == 0) {
    //只有命名构造函数 切没有加上BeanConstructor的注释 表示无法生成此Bean的构造函数
    beanParseErrorMap[rp.uri] = rp;
  } else {
    beanMap[uriKey] = rp;
  }
}

List<GBeanConstructor> _parseGBeanConstructors(
    ClassElement element, bool scanUsedWhiteList) {
  List<GBeanConstructor> constructors = [];
  element.constructors
      .where((ele) => !ele.name.startsWith("_"))
      .where((ele) =>
          scanUsedWhiteList ||
          "" == ele.name ||
          _beanConstructorNotAnnotation.firstAnnotationOf(ele) == null)
      .forEach((ele) {
    ConstantReader beanConstructor =
        ConstantReader(_beanConstructorAnnotation.firstAnnotationOf(ele));

    if (!beanConstructor.isNull || "" == ele.name || !scanUsedWhiteList) {
      String keyConstructorName = beanConstructor.isNull ||
              beanConstructor.peek("key").isNull ||
              beanConstructor.peek("key").stringValue.isEmpty
          ? ele.name
          : beanConstructor.peek("key").stringValue;

      GBeanConstructor gbc = GBeanConstructor(
        keyConstructorName,
        ele,
        beanConstructor,
        _parseGBeanFunctionParams(ele.parameters),
      );

      if ("" != gbc.namedConstructorInUri && "" == gbc.namedConstructor) {
        constructors
            .add(GBeanConstructor('', gbc.element, gbc.annotation, gbc.params));
      }
      constructors.add(gbc);
    }
  });

  return constructors;
}

List<Pair<String, GBeanMethod>> _parseGBeanMethods(
    ClassElement element, bool isScanSuper, bool scanUsedWhiteList) {
  List<Pair<String, GBeanMethod>> result = element.methods
      .where((e) => !e.name.startsWith('_'))
      .where((ele) =>
          scanUsedWhiteList ||
          _beanMethodNotAnnotation.firstAnnotationOf(ele) == null)
      .map((e) =>
          Pair(e, ConstantReader(_beanMethodAnnotation.firstAnnotationOf(e))))
      .where((e) => e.value != null && !e.value.isNull || !scanUsedWhiteList)
      .map((e) => GBeanMethod(
          e.key, e.value, _parseGBeanFunctionParams(e.key.parameters)))
      .map((e) => Pair(e.key, e))
      .toList(growable: true);
  if (isScanSuper) {
    result.addAll(_parseGBeanMethods(
        element.supertype.element, isScanSuper, scanUsedWhiteList));
  }
  return result;
}

List<Pair<String, GBeanField>> _parseGBeanFields(
    ClassElement element, bool isScanSuper, bool scanUsedWhiteList) {
  List<Pair<String, GBeanField>> result = element.fields
      .where((e) => !e.name.startsWith('_'))
      .where((ele) =>
          scanUsedWhiteList ||
          "" == ele.name ||
          _beanFieldNotAnnotation.firstAnnotationOf(ele) == null)
      .map((e) => BoxThree(
          e,
          ConstantReader(_beanFieldAnnotation.firstAnnotationOf(e)),
          parseAddImport(e.type)))
      .where((e) => (e.b != null && !e.b.isNull) || !scanUsedWhiteList)
      .map((e) => GBeanField(
            e.a,
            e.b,
            e.c.key,
            e.c.value,
            e.a.type.getDisplayString(),
            e.a.type,
          ))
      .map((e) => Pair(e.key, e))
      .toList(growable: true);
  if (isScanSuper) {
    result.addAll(_parseGBeanFields(
        element.supertype.element, isScanSuper, scanUsedWhiteList));
  }
  return result;
}

List<Pair<String, GBeanParam>> _parseGBeanFunctionParams(
    List<ParameterElement> parameters) {
  return parameters
      .map((e) => BoxThree(
          e,
          ConstantReader(_beanParamAnnotation.firstAnnotationOf(e)),
          parseAddImport(e.type)))
      .map((e) => GBeanParam(
            e.a,
            e.b,
            e.a.isNamed,
            e.c.key,
            e.c.value,
            e.a.type.getDisplayString(),
            e.a.type,
          ))
      .map((e) => Pair(e.key, e))
      .toList();
}

/**
 * 一下是Creator相关的扫描
 */

TypeChecker _customCreatorChecker =
    TypeChecker.fromRuntime(BeanCustomCreatorBase);

_scanBeanCreator(Element element, ConstantReader annotation) {
  if (element.kind != ElementKind.CLASS) return;

  if (!_customCreatorChecker.isAssignableFrom(element)) return;

  String clazz = element.displayName;
  String key = annotation.peek('key').stringValue;

  String uriKey = "'" + key + "'";
  MapEntry<String, String> imp =
      parseAddImports(element.librarySource.uri.toString());
  GBeanCreator pageGenerator = new GBeanCreator(
      key,
      (element as ClassElement),
      annotation,
      clazz,
      imp.key,
      imp.value,
      (element as ClassElement).thisType);

  if (!key.endsWith(".sys.bf.aymtools.dart")&&!key.endsWith("beanfactory.sys.aymtools.dart")) {
    if (!beanCreatorMap.containsKey(uriKey)) {
      beanCreatorMap[key] = pageGenerator;
    }
  }
  return;
}
