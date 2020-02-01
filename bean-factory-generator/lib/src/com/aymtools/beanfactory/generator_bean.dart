import 'dart:math' as Math;

import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'entities.dart';
import 'generator_factory.dart';

class ScanBeanGenerator extends GeneratorForAnnotation<Bean> {
  TypeChecker _beanConstructorAnnotation =
      TypeChecker.fromRuntime(BeanConstructor);
  TypeChecker _beanConstructorNotAnnotation =
      TypeChecker.fromRuntime(BeanConstructorNot);
  TypeChecker _beanParamAnnotation = TypeChecker.fromRuntime(BeanParam);

  TypeChecker _beanMethodAnnotation = TypeChecker.fromRuntime(BeanMethod);
  TypeChecker _beanMethodNotAnnotation = TypeChecker.fromRuntime(BeanMethodNot);

  TypeChecker _beanFieldAnnotation = TypeChecker.fromRuntime(BeanField);
  TypeChecker _beanFieldNotAnnotation = TypeChecker.fromRuntime(BeanFieldNot);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    _parseGBeanMap(BeanFactoryGenerator.beanMap, element, annotation,
        element.librarySource.uri.toString());

    return null;
  }

  Map<String, GBean> _parseGBeanMap(Map<String, GBean> gBeanMap,
      Element element, ConstantReader annotation, String sourceUri) {
    if (element.kind != ElementKind.CLASS) return gBeanMap;
    ConstantReader from = annotation.peek("needAssignableFrom");
//    print(
//        "check : ${from.listValue.map((e) => e.toTypeValue()).every((c) => TypeChecker.fromStatic(c).isAssignableFrom(element))}");
    if (!from.isNull &&
        from.isList &&
        from.listValue.isNotEmpty &&
        !from.listValue
            .map((e) => e.toTypeValue())
            .every((c) => TypeChecker.fromStatic(c).isAssignableFrom(element)))
      return gBeanMap;

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
      keyGen = BeanFactoryGenerator
          .keyGens[annotation.peek('keyGen').objectValue.type.getDisplayString()];
    }
    if (keyGen == null) {
      keyGen = KeyGenByClassName();
    }
    String uriKey = keyGen.gen(key, tag, ext, clazz, sourceUri);
    if ("" == uriKey)
      uriKey = KeyGenByClassName().gen(key, tag, ext, clazz, sourceUri);

    if (gBeanMap.containsKey(uriKey)) {
      return gBeanMap;
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
      BeanFactoryGenerator.parseAddImportList(
              sourceUri, BeanFactoryGenerator.imports)
          .value,
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
                            ConstantReader(_beanConstructorAnnotation
                                .firstAnnotationOf(e)),
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

//    print("${rp.elementName}:$scanMethods: ${rp.methods.length} : ");
    if (rp.constructors.length == 0) {
      //只有命名构造函数 切没有加上BeanConstructor的注释 表示无法生成此Bean的构造函数
      BeanFactoryGenerator.beanParseErrorMap[rp.uri] = rp;
    } else {
      gBeanMap[uriKey] = rp;
    }
    return gBeanMap;
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
          constructors.add(
              GBeanConstructor('', gbc.element, gbc.annotation, gbc.params));
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
            BeanFactoryGenerator.parseAAddImportList(
                e.type, BeanFactoryGenerator.imports)))
        .where((e) => (e.b != null && !e.b.isNull) || !scanUsedWhiteList)
        .map((e) => GBeanField(
              e.a,
              e.b,
              e.c.key,
              e.c.value,
              e.a.type.getDisplayString(),
              e.a.type,
              e.a.runtimeType,
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
            BeanFactoryGenerator.parseAAddImportList(
                e.type, BeanFactoryGenerator.imports)))
        .map((e) => GBeanParam(
              e.a,
              e.b,
              e.a.isNamed,
              e.c.key,
              e.c.value,
              e.a.type.getDisplayString(),
              e.a.type,
              e.a.runtimeType,
            ))
        .map((e) => Pair(e.key, e))
        .toList();
  }
}

class GBeanCreatorBySysGenerator {
  String generateBeanSwitchConstructorInstance(GBean gBean,
      String namedConstructorInUri, String paramsMapName, String objParamName) {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("${gBean.clsType_} beanInstance;");
    stringBuffer.writeln("  switch ($namedConstructorInUri) {");
    gBean.constructors.forEach((pair) {
      GBeanConstructor constructor = pair.value;

      String resultStr = 'beanInstance';

      String newBeanCMD =
          "${gBean.typeAsStr}.${gBean.typeName}${'' == constructor.namedConstructor ? '' : '.${constructor.namedConstructor}'}";

      stringBuffer.writeln("    case '${constructor.namedConstructorInUri}' :");
      stringBuffer.writeln("");
      List<String> gpsccnp =
          _generateBeanSwitchConstructorCheckNumParamsInstance(constructor,
                  paramsMapName, objParamName, resultStr, newBeanCMD)
              .where((ifStr) => ifStr != "")
              .toList();
      if (gpsccnp.length > 0) {
        gpsccnp.forEach((s) {
          stringBuffer.writeln("$s else ");
        });

        stringBuffer.writeln("{");
        //当所有条件都不满足时 但路由有无参的构造函数 时使用无参的构造函数来 创建
        if (constructor.params.length == 0 ||
            constructor.canCreateForNoParams) {
          stringBuffer.write(_generateBeanConstructorOrFunctionParams(
              resultStr, newBeanCMD, [], []));
        }
        stringBuffer.writeln("        }");
      }
      stringBuffer.writeln("");
      stringBuffer.writeln("");
      stringBuffer.writeln("");
      stringBuffer.writeln("      break;");
    });
    stringBuffer.writeln("  }");
    stringBuffer.writeln("return beanInstance;");
    return stringBuffer.toString();
  }

  List<String> _generateBeanSwitchConstructorCheckNumParamsInstance(
      GBeanConstructor constructor,
      String paramsMapName,
      String objParamName,
      String resultStr,
      String newBeanCMD) {
    List<String> result = [];
    //无参构造函数
    if (constructor.canCreateForNoParams) {
      result.add(
          "if ($paramsMapName == null && $objParamName == null) {$resultStr=$newBeanCMD();}");
    }

    //仅使用传入参数的构造函数 非Map
    if (constructor.canCreateForOneParam) {
      GBeanParam param;
      if (constructor.params.length == 1) {
        param = constructor.params[0].value;
      } else {
        param =
            constructor.params.firstWhere((pair) => !pair.value.isNamed).value;
      }

      StringBuffer codeBuffer = StringBuffer();
      //map 交给下边处理 这里略过map
      if (!param.isTypeDartCoreMap) {
        codeBuffer
            .write("if ($paramsMapName == null && $objParamName != null)  {");
        String paramType = param.paramType;
        codeBuffer.write("if ($objParamName is $paramType) {");
        codeBuffer.write(_generateBeanConstructorOneParams(
            resultStr, newBeanCMD, param, "$objParamName"));
        codeBuffer.write("}");
        if (param.isTypeDartCoreString) {
          codeBuffer.write(
              "else if(($objParamName is num)||($objParamName is bool)){");
          codeBuffer.write(_generateBeanConstructorOneParams(
              resultStr, newBeanCMD, param, "$objParamName.toString()"));
          codeBuffer.write("}");
        } else if (param.isTypeDartCoreBase) {
          codeBuffer.write("else if($objParamName is String){");
          if (param.type.isDartCoreBool) {
            codeBuffer.write(_generateBeanConstructorOneParams(resultStr,
                newBeanCMD, param, "'true'==$objParamName ? true : false"));
          } else if (param.type.isDartCoreInt) {
            codeBuffer.write(_generateBeanConstructorOneParams(
                resultStr, newBeanCMD, param, "int.tryParse($objParamName)"));
          } else if (param.type.isDartCoreDouble) {
            codeBuffer.write(_generateBeanConstructorOneParams(resultStr,
                newBeanCMD, param, "double.tryParse($objParamName)"));
          }
          codeBuffer.write("}");
        }
        codeBuffer.write("}");
        result.add(codeBuffer.toString());
      }
    }

    //仅使用传入参数的构造函数 专注Map
    if (constructor.canCreateForOneParam) {
      GBeanParam param;
      if (constructor.params.length == 1) {
        param = constructor.params[0].value;
      } else {
        param =
            constructor.params.firstWhere((pair) => !pair.value.isNamed).value;
      }
      //判断时map 并且没有指定 在map中的key
      if (param.isTypeDartCoreMap && "" == param.key) {
        ///uri中无参数 只有传入的Map参数
        StringBuffer codeBuffer = StringBuffer();
        codeBuffer.write(
            "if ($paramsMapName != null && $paramsMapName == $objParamName && $objParamName is Map<String,dynamic>)  {");
        codeBuffer.write(_generateBeanConstructorOneParams(
            resultStr, newBeanCMD, param, objParamName));
        codeBuffer.write("}");
        result.add(codeBuffer.toString());
      }
    }

    //混杂模式 既有传入参数 也有uri中的参数 但构造函数有且只用map 并且未指定map中key
    if (constructor.params.length == 1 &&
        constructor.params[0].value.isTypeDartCoreMap &&
        "" == constructor.params[0].value.key) {
      GBeanParam param = constructor.params[0].value;
      StringBuffer codeBuffer = StringBuffer();
      /////有且只有路径参数
      codeBuffer.clear();
      codeBuffer
          .write("if ($paramsMapName != null && $objParamName == null)  {");
      codeBuffer.write(_generateBeanConstructorOneParams(
          resultStr, newBeanCMD, param, paramsMapName));
      codeBuffer.write("}");
      result.add(codeBuffer.toString());

      //同时包含了路径参数和传入的map参数
      codeBuffer.clear();
      codeBuffer.write(
          "if ($paramsMapName != null &&  $objParamName != null && "
          " $paramsMapName != $objParamName && ($objParamName is Map<String, dynamic>))  {");
      codeBuffer.write(_generateBeanConstructorOneParams(
          resultStr, newBeanCMD, param, paramsMapName));
      codeBuffer.write("}");
      result.add(codeBuffer.toString());

      //同时包含了路径参数和传入的map参数
      codeBuffer.clear();
      codeBuffer.write(
          "if ($paramsMapName != null &&  $objParamName != null && "
          " $paramsMapName != $objParamName && ($objParamName is Map<String, dynamic>))  {");
      codeBuffer.write(_generateBeanConstructorOneParams(
          resultStr, newBeanCMD, param, paramsMapName));
      codeBuffer.write("}");
      result.add(codeBuffer.toString());
    }

    ////以上都是无参 或者单参数的构造函数来构造

    //既要传入的参数 也要 uri的参数   有可能要废掉 因为会与map中取值冲突
    if (constructor.params.length == 2 &&
        "" == constructor.params[0].value.key &&
        !constructor.params[0].value.isNamed &&
        "" == constructor.params[1].value.key &&
        !constructor.params[1].value.isNamed &&
        constructor.params[1].value.isTypeDartCoreMap) {
      GBeanParam param1 = constructor.params[0].value;
      GBeanParam param2 = constructor.params[1].value;

      StringBuffer codeBuffer = StringBuffer();
      if (param1.isTypeDartCoreMap) {
        codeBuffer
            .write("if ($paramsMapName == null && $objParamName==null) {");
        codeBuffer.write(
            _generateBeanConstructorOrFunctionParams(resultStr, newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer
            .write("else if ($paramsMapName != null && $objParamName==null) {");
        codeBuffer.write(_generateBeanConstructorOrFunctionParams(
            resultStr, newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          paramsMapName
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if ($paramsMapName == null && $objParamName!=null && ($objParamName is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorOrFunctionParams(
            resultStr, newBeanCMD, [
          param1,
          param2
        ], [
          objParamName,
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if ($paramsMapName != null && $objParamName!=null && ($objParamName is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorOrFunctionParams(resultStr,
            newBeanCMD, [param1, param2], [objParamName, paramsMapName]));
        codeBuffer.write("}");
      } else {
        codeBuffer
            .write("if ($paramsMapName == null && $objParamName==null) {");
        codeBuffer.write(
            _generateBeanConstructorOrFunctionParams(resultStr, newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer
            .write("else if ($paramsMapName != null && $objParamName==null) {");
        codeBuffer.write(_generateBeanConstructorOrFunctionParams(
            resultStr, newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          paramsMapName
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if ($paramsMapName == null && $objParamName!=null && ($objParamName is ${param1.paramType}) && !($objParamName is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorOrFunctionParams(
            resultStr, newBeanCMD, [
          param1,
          param2
        ], [
          objParamName,
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if ($paramsMapName != null && $objParamName!=null && ($objParamName is ${param1.paramType}) && !($objParamName is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorOrFunctionParams(resultStr,
            newBeanCMD, [param1, param2], [objParamName, paramsMapName]));
        codeBuffer.write("}");
      }

      result.add(codeBuffer.toString());
    }

    //如果时无参构造 或者第一个（非无指定mapkey的参数类型且是map）的构造函数
    if (constructor.params.length == 0 ||
        (constructor.params.length > 0 &&
            !(constructor.params[0].value.isTypeDartCoreMap &&
                "" == constructor.params[0].value.key))) {
      result.add(
          "if($paramsMapName!=null) {${generateBeanSwitchConstructorOrFunctionParamsForMap(resultStr, newBeanCMD, constructor.params.map((pair) => pair.value).toList(), paramsMapName)}\n}");
    }
    return result;
  }

  String generateBeanSwitchGBeanMethodInvoker(
      GBean bean, String methodName, String beanName, String paramsMapName) {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("  switch ($methodName) {");
    bean.methods.map((e) => e.value).forEach((m) {
      stringBuffer.writeln("case '${m.methodNameKey}' : ");
      String ifStr = generateBeanSwitchConstructorOrFunctionParamsForMap(
          m.isResultVoid ? '' : 'dynamic result',
          "$beanName.${m.methodName}",
          m.params.map((e) => e.value).toList(),
          paramsMapName,
          cmdAfter: [m.isResultVoid ? 'return ;' : 'return result;']);
      stringBuffer.writeln(ifStr);
      if (ifStr.trimLeft().startsWith("if")) {
        stringBuffer.writeln(
            "throw IllegalArgumentException(${bean.clsType_},'${m.methodName}', [${m.params.map((e) => "Pair('${e.value.keyInMaps}',${e.value.paramType})").reduce((v, e) => "$v,$e")}], $paramsMapName.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList()); ");
      } else {
        stringBuffer.writeln("break;");
      }
    });
    stringBuffer.writeln("  }");
    return stringBuffer.toString();
  }

  String generateBeanSwitchConstructorOrFunctionParamsForMap(String resultStr,
      String CMD, List<GBeanParam> params, String paramsMapName,
      {List<String> cmdAfter = const []}) {
    List<GBeanParam> paramsNamed = params.where((p) => p.isNamed).toList();

    List<_IFGenerator> paramsNeed = params
        .where((p) => !p.isNamed)
        .map((p) => _IFGenerator(p, paramsMapName, isSelect: true))
        .toList();
    List<_IFGenerator> noParamsNeedCanRun;

    String ifsStr = _combination(paramsNamed, paramsMapName)
        .where((list) {
          dynamic no = findFistWhere(list, (p) => p.isSelect);

          if (no == null) {
            noParamsNeedCanRun = list;
          }

          return no != null;
        })
        .map((list) {
          List<_IFGenerator> r = cloneList(paramsNeed, (ifg) => ifg.clone());
          r.addAll(list);
          return r;
        })
        .map((list) => _generateBeanSwitchConstructorOrFunctionParamsForMapIf(
            resultStr, CMD, list,
            cmdAfter: cmdAfter))
        .where((str) => "" != str)
        .map((ifs) => "\n$ifs else ")
        .fold("", (i, s) => "$i$s");

    if (ifsStr.trimRight().endsWith("else")) {
      ifsStr = ifsStr.substring(0, ifsStr.length - 6);
    }

    ////需要单独处理 当named参数全不选时的状况
    if (noParamsNeedCanRun != null) {
      if (paramsNeed.length == 0) {
        if (ifsStr.trimLeft().startsWith("if")) {
          ifsStr +=
              "else {${_generateBeanConstructorOrFunctionParams(resultStr, CMD, [], [], cmdAfter: cmdAfter)}}";
        } else {
          ifsStr +=
              "${_generateBeanConstructorOrFunctionParams(resultStr, CMD, [], [], cmdAfter: cmdAfter)}";
        }
      } else {
        if (ifsStr.trimLeft().startsWith("if")) {
          ifsStr +=
              "else ${_generateBeanSwitchConstructorOrFunctionParamsForMapIf(resultStr, CMD, paramsNeed, cmdAfter: cmdAfter)}";
        } else {
          ifsStr += _generateBeanSwitchConstructorOrFunctionParamsForMapIf(
              resultStr, CMD, paramsNeed,
              cmdAfter: cmdAfter);
        }
      }
    }

    return (ifsStr);
  }

  String _generateBeanSwitchConstructorOrFunctionParamsForMapIf(
      String resultStr, String CMD, List<_IFGenerator> params,
      {List<String> cmdAfter = const []}) {
    BoxThree<String, List<String>, String> bt = params
//        .where((ifg) => ifg.isSelect)
        .map((ifg) =>
            BoxThree(ifg.whereStr, ifg.contentStr, ifg.otherContentStr))
        .fold(BoxThree("", <String>[], ""), (i, n) {
      i.a += "${n.a}  && ";
      if ("" != n.b) i.b.add(n.b);
      i.c += " \n${n.c.trim()}";
      return i;
    });

    String r =
        "if (${bt.a.trimRight().endsWith("&&") ? bt.a.substring(0, bt.a.length - 3) : bt.a} ) { ${bt.c.trim()} \n ${_generateBeanConstructorOrFunctionParams(resultStr, CMD, params.where((ifg) => ifg.isSelect).map((ifg) => ifg.param).toList(), bt.b, cmdAfter: cmdAfter)} \n }";

    return r;
  }

  List<GBeanParam> _cloneListParams(List<GBeanParam> source) {
//    return cloneList(source, (e) => e.clone());
    return cloneList(source, (e) => e);
  }

//相比穷举的快速生成方案 参考自来源https://zhenbianshu.github.io/2019/01/charming_alg_permutation_and_combination.html
  List<List<_IFGenerator>> _combination(
      List<GBeanParam> source, String paramsMapName) {
    List<List<_IFGenerator>> result = [<_IFGenerator>[]];

    //将所有的参数全必选的选项加入到返回结果中
    result.add(_cloneListParams(source)
        .map((p) => _IFGenerator(p, paramsMapName, isSelect: true))
        .toList(growable: true));

    for (int i = 1; i < Math.pow(2, source.length) - 1; i++) {
//      Set<RoutePageParam> eligibleCollections = Set();
      List<_IFGenerator> paras = _cloneListParams(source)
          .map((p) => _IFGenerator(p, paramsMapName))
          .toList(growable: true);
      // 依次将数字 i 与 2^n 按位与，判断第 n 位是否为 1
      for (int j = 0; j < source.length; j++) {
        if ((i & Math.pow(2, j).toInt()) == Math.pow(2, j)) {
          //          eligibleCollections.add(source[j]);
          paras[j].isSelect = true;
        } else {}
      }
      result.add(paras);
    }
    //将所有的参数全不选的选项加入到返回结果中
    result.add(_cloneListParams(source)
        .map((p) => _IFGenerator(p, paramsMapName))
        .toList(growable: true));
    return result;
  }

  String _generateBeanConstructorOneParams(
      String resultStr, String newBeanCMD, GBeanParam param, String value,
      {List<String> cmdAfter = const []}) {
    return _generateBeanConstructorOrFunctionParams(
        resultStr, newBeanCMD, [param], [value],
        cmdAfter: cmdAfter);
  }

  String _generateBeanConstructorOrFunctionParams(String resultStr, String CMD,
      List<GBeanParam> params, List<String> values,
      {List<String> cmdAfter = const []}) {
    if (params.length != values.length)
      throw Exception(
          "_generateBeanConstructorOrFunctionParams params.length!=values.length");

    StringBuffer codeBuffer = StringBuffer();
    if (resultStr.isEmpty) {
      codeBuffer.write("$CMD(");
    } else {
      codeBuffer.write("$resultStr=$CMD(");
    }
    for (var i = 0; i < params.length; i++) {
      GBeanParam param = params[i];
      String value = values[i];
      if (param.isNamed) {
        codeBuffer.write("${param.paramName}:$value");
      } else {
        codeBuffer.write("$value");
      }
      if (i < params.length - 1) {
        codeBuffer.write(",");
      }
    }
    codeBuffer.write(");");
    if (cmdAfter.isNotEmpty) {
      codeBuffer.write(cmdAfter.reduce((v, e) => v + e));
    }
    return codeBuffer.toString();
  }

  dynamic _generateBeanParamDefValueByDartCoreTypeBase(GBeanParam param) {
    switch (param.paramType) {
      case "int":
        return 0;
      case "double":
        return 0.0;
      case "num":
        return 0;
      case "bool":
        return false;
      case "String":
        return "";
      case "Map":
        return {};
      case "List":
        return [];
      default:
        return null;
    }
  }
}

class _IFGenerator {
  final GBeanParam param;
  final String paramsMapName;
  bool isSelect;

  final List<String> otherContent;

  _IFGenerator(this.param, this.paramsMapName,
      {this.isSelect = false, this.otherContent = const []});

  String get whereStr {
    if (!isSelect) return "!$paramsMapName.containsKey('${param.keyInMaps}')";
    String w = "";
    if ("String" == param.paramType) {
      w = "($paramsMapName.containsKey('${param.keyInMaps}') && "
          "($paramsMapName['${param.keyInMaps}'] is ${param.paramType} "
          "|| $paramsMapName['${param.keyInMaps}'] is num || $paramsMapName['${param.keyInMaps}'] is bool))";
    } else if ("int" == param.paramType) {
      w = "($paramsMapName.containsKey('${param.keyInMaps}') && "
          "($paramsMapName['${param.keyInMaps}'] is ${param.paramType} || $paramsMapName['${param.keyInMaps}'] is String))";
    } else if ("double" == param.paramType) {
      w = "($paramsMapName.containsKey('${param.keyInMaps}') && "
          "($paramsMapName['${param.keyInMaps}'] is ${param.paramType} || $paramsMapName['${param.keyInMaps}'] is String))";
    } else if ("bool" == param.paramType) {
      w = "($paramsMapName.containsKey('${param.keyInMaps}') && "
          "($paramsMapName['${param.keyInMaps}'] is ${param.paramType} || $paramsMapName['${param.keyInMaps}'] is String))";
    } else {
      w = "($paramsMapName.containsKey('${param.keyInMaps}') && "
          "($paramsMapName['${param.keyInMaps}'] is ${param.paramType}))";
    }
    return w;
  }

  String get contentStr {
    if (!isSelect) return "";
    String c = "";
    if ("String" == param.paramType) {
      c = "$paramsMapName['${param.keyInMaps}'] is ${param.paramType} ? $paramsMapName['${param.keyInMaps}'] as ${param.paramType} : $paramsMapName['${param.keyInMaps}'].toString()";
    } else if ("int" == param.paramType) {
      c = "$paramsMapName['${param.keyInMaps}'] is ${param.paramType} ? $paramsMapName['${param.keyInMaps}'] as ${param.paramType} : "
          "(int.parse( $paramsMapName['${param.keyInMaps}']) )";
    } else if ("double" == param.paramType) {
      c = "$paramsMapName['${param.keyInMaps}'] is ${param.paramType} ? $paramsMapName['${param.keyInMaps}'] as ${param.paramType} : "
          "(double.parse( $paramsMapName['${param.keyInMaps}']) )";
    } else if ("bool" == param.paramType) {
      c = "$paramsMapName['${param.keyInMaps}'] is ${param.paramType} ? $paramsMapName['${param.keyInMaps}'] as ${param.paramType} : "
          "('true'==$paramsMapName['${param.keyInMaps}'] ? true : false )";
    } else {
      c = "$paramsMapName['${param.keyInMaps}'] as ${param.paramType}";
    }
    return c;
  }

  String get otherContentStr =>
      otherContent.fold("", (i, n) => "$i $n \n").trimRight();

  _IFGenerator clone() {
    _IFGenerator r = _IFGenerator(param, paramsMapName,
        isSelect: isSelect, otherContent: cloneList(otherContent, (s) => s));
    return r;
  }
}
