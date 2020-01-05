import 'dart:math' as Math;

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'entities.dart';
import 'generator_factory.dart';

class ScanBeanGenerator extends GeneratorForAnnotation<Bean> {
  TypeChecker beanConstructorAnnotation =
      TypeChecker.fromRuntime(BeanConstructor);
  TypeChecker beanParamAnnotation = TypeChecker.fromRuntime(BeanCreateParam);

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
    if (!from.isNull &&
        from.isList &&
        from.listValue.isNotEmpty &&
        !TypeChecker.any(from.listValue
                .map((f) => TypeChecker.fromStatic(f.toTypeValue())))
            .isAssignableFrom(element)) return gBeanMap;

    String clazz = element.displayName;
    String uri = annotation.peek('uri').stringValue;

    String tag = annotation.peek('tag').stringValue;
    int ext = annotation.peek('ext').intValue;

    String genName = annotation.peek('keyGen').objectValue.type.name;
//    print("$sourceUri : genClassName:$genName");
    KeyGen keyGen = BeanFactoryGenerator.keyGens[genName];
    if (keyGen == null) {
      keyGen = KeyGenByClassName();
    }
    String uriKey = keyGen.gen(uri, tag, ext, clazz, sourceUri);
    if ("" == uriKey)
      uriKey = KeyGenByClassName().gen(uri, tag, ext, clazz, sourceUri);

    if (gBeanMap.containsKey(uriKey)) {
      return gBeanMap;
    }
    GBean rp = GBean(
        uriKey,
        clazz,
        sourceUri,
        BeanFactoryGenerator.parseAddImportList(
                sourceUri, BeanFactoryGenerator.imports)
            .value,
        tag,
        ext,
        (element as ClassElement),
        annotation);

    _parseGBeanParams(rp, (element as ClassElement));

    if (rp.constructors.length == 0) {
      //只有命名构造函数 切没有加上BeanConstructor的注释 表示无法生成此Bean的构造函数
      BeanFactoryGenerator.beanParseErrorMap[rp.uri] = rp;
    } else {
      gBeanMap[uriKey] = rp;
    }
    return gBeanMap;
  }

  void _parseGBeanParams(GBean routePage, ClassElement element) {
//    if (element.constructors.length == 1 &&
//        element.constructors[0].parameters.length == 0) return;

    element.constructors
        .where((ele) => !ele.name.startsWith("_"))
        .forEach((ele) {
      ConstantReader beanConstructor =
          ConstantReader(beanConstructorAnnotation.firstAnnotationOf(ele));

      if (!beanConstructor.isNull || "" == ele.name) {
        String keyConstructorName = beanConstructor.isNull
            ? ele.name
            : ('' == beanConstructor.peek("namedConstructor").stringValue
                ? ele.name
                : beanConstructor.peek("namedConstructor").stringValue);

        String constructorName = ele.name;

        GBeanConstructor gbc =
            GBeanConstructor(keyConstructorName, constructorName);

        ele.parameters.forEach((e) {
          ConstantReader beanParam =
              ConstantReader(beanParamAnnotation.firstAnnotationOf(e));
          String key =
              beanParam.isNull || '' == beanParam.peek("keyInMap").stringValue
                  ? ""
                  : beanParam.peek("keyInMap").stringValue;

          Pair<String, String> importPair =
              BeanFactoryGenerator.parseAAddImportList(
                  e.type, BeanFactoryGenerator.imports);

          gbc.params.add(new Pair(
              key,
              new GBeanCreateParam(key, e.name, e.isNamed, importPair.key,
                  importPair.value, e.type.name, e.type, e.runtimeType)));
        });

        if ("" == constructorName && "" != keyConstructorName) {
//          GBeanConstructor gbcDEF =
//              ;
//          gbcDEF.params = gbc.params;
          routePage.constructors.add(new Pair(
              constructorName,
              GBeanConstructor(constructorName, constructorName)
                ..params = gbc.params));
        }
        routePage.constructors.add(new Pair(keyConstructorName, gbc));
      }
    });
  }
}

class GBeanCreatorBySysGenerator {
  String generateBeanSwitchConstructorInstance(GBean gBean) {
    StringBuffer stringBuffer = StringBuffer();
    stringBuffer.writeln("  switch (namedConstructorInRouter) {");
    gBean.constructors.forEach((pair) {
      GBeanConstructor constructor = pair.value;

      String newBeanCMD =
          "${gBean.typeAsStr}.${gBean.typeName}${'' == constructor.namedConstructorInEntity ? '' : '.${constructor.namedConstructorInEntity}'}";
      stringBuffer
          .writeln("    case '${constructor.namedConstructorInRouter}' :");
      stringBuffer.writeln("");
      List<String> gpsccnp =
          _generateBeanSwitchConstructorCheckNumParamsInstance(
                  constructor, newBeanCMD)
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
          stringBuffer
              .write(_generateBeanConstructorParams(newBeanCMD, [], []));
        }
        stringBuffer.writeln("        }");
      }
      stringBuffer.writeln("");
      stringBuffer.writeln("");
      stringBuffer.writeln("");
      stringBuffer.writeln("      break;");
    });
    stringBuffer.writeln("  }");
    return stringBuffer.toString();
  }

  List<String> _generateBeanSwitchConstructorCheckNumParamsInstance(
      GBeanConstructor constructor, String newBeanCMD) {
    List<String> result = [];
    //无参构造函数
    if (constructor.canCreateForNoParams) {
      result.add(
          "if (mapParam == null && objParam == null) {beanInstance=$newBeanCMD();}");
    }

    //仅使用传入参数的构造函数 非Map
    if (constructor.canCreateForOneParam) {
      GBeanCreateParam param;
      if (constructor.params.length == 1) {
        param = constructor.params[0].value;
      } else {
        param =
            constructor.params.firstWhere((pair) => !pair.value.isNamed).value;
      }

      StringBuffer codeBuffer = StringBuffer();
      //map 交给下边处理 这里略过map
      if (!param.isTypeDartCoreMap) {
        codeBuffer.write("if (mapParam == null && objParam != null)  {");
        String paramType = param.paramType;
        codeBuffer.write("if (objParam is $paramType) {");
        codeBuffer.write(
            _generateBeanConstructorOneParams(param, newBeanCMD, "objParam"));
        codeBuffer.write("}");
        if (param.isTypeDartCoreString) {
          codeBuffer.write("else if((objParam is num)||(objParam is bool)){");
          codeBuffer.write(_generateBeanConstructorOneParams(
              param, newBeanCMD, "objParam.toString()"));
          codeBuffer.write("}");
        } else if (param.isTypeDartCoreBase) {
          codeBuffer.write("else if(objParam is String){");
          if (param.type.isDartCoreBool) {
            codeBuffer.write(_generateBeanConstructorOneParams(
                param, newBeanCMD, "'true'==objParam ? true : false"));
          } else if (param.type.isDartCoreInt) {
            codeBuffer.write(_generateBeanConstructorOneParams(
                param, newBeanCMD, "int.tryParse(objParam)"));
          } else if (param.type.isDartCoreDouble) {
            codeBuffer.write(_generateBeanConstructorOneParams(
                param, newBeanCMD, "double.tryParse(objParam)"));
          }
          codeBuffer.write("}");
        }
        codeBuffer.write("}");
        result.add(codeBuffer.toString());
      }
    }

    //仅使用传入参数的构造函数 专注Map
    if (constructor.canCreateForOneParam) {
      GBeanCreateParam param;
      if (constructor.params.length == 1) {
        param = constructor.params[0].value;
      } else {
        param =
            constructor.params.firstWhere((pair) => !pair.value.isNamed).value;
      }
      //判断时map 并且没有指定 在map中的key
      if (param.isTypeDartCoreMap && "" == param.keyInMap) {
        ///uri中无参数 只有传入的Map参数
        StringBuffer codeBuffer = StringBuffer();
        codeBuffer.write(
            "if (mapParam != null && mapParam == objParam && objParam is Map<String,dynamic>)  {");
        codeBuffer.write(
            _generateBeanConstructorOneParams(param, newBeanCMD, "objParam"));
        codeBuffer.write("}");
        result.add(codeBuffer.toString());
      }
    }

    //混杂模式 既有传入参数 也有uri中的参数 但构造函数有且只用map 并且未指定map中key
    if (constructor.params.length == 1 &&
        constructor.params[0].value.isTypeDartCoreMap &&
        "" == constructor.params[0].value.keyInMap) {
      GBeanCreateParam param = constructor.params[0].value;
      StringBuffer codeBuffer = StringBuffer();
      /////有且只有路径参数
      codeBuffer.clear();
      codeBuffer.write("if (mapParam != null && objParam == null)  {");
      codeBuffer.write(
          _generateBeanConstructorOneParams(param, newBeanCMD, "mapParam"));
      codeBuffer.write("}");
      result.add(codeBuffer.toString());

      //同时包含了路径参数和传入的map参数
      codeBuffer.clear();
      codeBuffer.write("if (mapParam != null &&  objParam != null && "
          " mapParam != objParam && (objParam is Map<String, dynamic>))  {");
      codeBuffer.write(
          _generateBeanConstructorOneParams(param, newBeanCMD, "mapParam"));
      codeBuffer.write("}");
      result.add(codeBuffer.toString());

      //同时包含了路径参数和传入的map参数
      codeBuffer.clear();
      codeBuffer.write("if (mapParam != null &&  objParam != null && "
          " mapParam != objParam && (objParam is Map<String, dynamic>))  {");
      codeBuffer.write(
          _generateBeanConstructorOneParams(param, newBeanCMD, "mapParam"));
      codeBuffer.write("}");
      result.add(codeBuffer.toString());
    }

    ////以上都是无参 或者单参数的构造函数来构造

    //既要传入的参数 也要 uri的参数   有可能要废掉 因为会与map中取值冲突
    if (constructor.params.length == 2 &&
        "" == constructor.params[0].value.keyInMap &&
        !constructor.params[0].value.isNamed &&
        "" == constructor.params[1].value.keyInMap &&
        !constructor.params[1].value.isNamed &&
        constructor.params[1].value.isTypeDartCoreMap) {
      GBeanCreateParam param1 = constructor.params[0].value;
      GBeanCreateParam param2 = constructor.params[1].value;

      StringBuffer codeBuffer = StringBuffer();
      if (param1.isTypeDartCoreMap) {
        codeBuffer.write("if (mapParam == null && objParam==null) {");
        codeBuffer.write(_generateBeanConstructorParams(newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer.write("else if (mapParam != null && objParam==null) {");
        codeBuffer.write(_generateBeanConstructorParams(newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          "mapParam"
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if (mapParam == null && objParam!=null && (objParam is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorParams(newBeanCMD, [
          param1,
          param2
        ], [
          "objParam",
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if (mapParam != null && objParam!=null && (objParam is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorParams(
            newBeanCMD, [param1, param2], ["objParam", "mapParam"]));
        codeBuffer.write("}");
      } else {
        codeBuffer.write("if (mapParam == null && objParam==null) {");
        codeBuffer.write(_generateBeanConstructorParams(newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer.write("else if (mapParam != null && objParam==null) {");
        codeBuffer.write(_generateBeanConstructorParams(newBeanCMD, [
          param1,
          param2
        ], [
          "${_generateBeanParamDefValueByDartCoreTypeBase(param1)}",
          "mapParam"
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if (mapParam == null && objParam!=null && (objParam is ${param1.paramType}) && !(objParam is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorParams(newBeanCMD, [
          param1,
          param2
        ], [
          "objParam",
          "${_generateBeanParamDefValueByDartCoreTypeBase(param2)}"
        ]));
        codeBuffer.write("}");
        codeBuffer.write(
            "else if (mapParam != null && objParam!=null && (objParam is ${param1.paramType}) && !(objParam is Map<String, dynamic>)) {");
        codeBuffer.write(_generateBeanConstructorParams(
            newBeanCMD, [param1, param2], ["objParam", "mapParam"]));
        codeBuffer.write("}");
      }

      result.add(codeBuffer.toString());
    }

    //如果时无参构造 或者第一个（非无指定mapkey的参数类型且是map）的构造函数
    if (constructor.params.length == 0 ||
        (constructor.params.length > 0 &&
            !(constructor.params[0].value.isTypeDartCoreMap &&
                "" == constructor.params[0].value.keyInMap))) {
      result.add(
          "if(mapParam!=null) {${_generateBeanSwitchConstructorParamsForMapInstance(constructor, newBeanCMD)}\n}");
    }
    return result;
  }

  String _generateBeanSwitchConstructorParamsForMapInstance(
      GBeanConstructor constructor, String newBeanCMD) {
    List<GBeanCreateParam> params =
        constructor.params.map((pair) => pair.value).toList();

    List<GBeanCreateParam> paramsNamed =
        params.where((p) => p.isNamed).toList();

    List<_IFGenerator> paramsNeed = params
        .where((p) => !p.isNamed)
        .map((p) => _IFGenerator(p, isSelect: true))
        .toList();
    List<_IFGenerator> noParamsNeedCanCreate;

    String ifsStr = _combination(paramsNamed)
        .where((list) {
          dynamic no = findFistWhere(list, (p) => p.isSelect);

          if (no == null) {
            noParamsNeedCanCreate = list;
          }

          return no != null;
        })
        .map((list) {
          List<_IFGenerator> r = cloneList(paramsNeed, (ifg) => ifg.clone());
          r.addAll(list);
          return r;
        })
        .map((list) => _generateBeanSwitchConstructorParamsForMapIfInstance(
            list, newBeanCMD))
        .where((str) => "" != str)
        .map((ifs) => "\n$ifs else ")
        .fold("", (i, s) => "$i$s");

    if (ifsStr.trimRight().endsWith("else")) {
      ifsStr = ifsStr.substring(0, ifsStr.length - 6);
    }

    ////需要单独处理 当named参数全不选时的状况
    if (noParamsNeedCanCreate != null) {
      if (paramsNeed.length == 0) {
        if (ifsStr.trimLeft().startsWith("if")) {
          ifsStr +=
              "else {${_generateBeanConstructorParams(newBeanCMD, [], [])}}";
        } else {
          ifsStr += "${_generateBeanConstructorParams(newBeanCMD, [], [])}";
        }
      } else {
        ifsStr += _generateBeanSwitchConstructorParamsForMapIfInstance(
            paramsNeed, newBeanCMD);
      }
    }

    return (ifsStr);
  }

  String _generateBeanSwitchConstructorParamsForMapIfInstance(
      List<_IFGenerator> params, String newBeanCMD) {
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
        "if (${bt.a.trimRight().endsWith("&&") ? bt.a.substring(0, bt.a.length - 3) : bt.a} ) { ${bt.c.trim()} \n ${_generateBeanConstructorParams(newBeanCMD, params.where((ifg) => ifg.isSelect).map((ifg) => ifg.param).toList(), bt.b)} \n }";

    return r;
  }

  List<GBeanCreateParam> _cloneListParams(List<GBeanCreateParam> source) {
//    return cloneList(source, (e) => e.clone());
    return cloneList(source, (e) => e);
  }

//相比穷举的快速生成方案 参考自来源https://zhenbianshu.github.io/2019/01/charming_alg_permutation_and_combination.html
  List<List<_IFGenerator>> _combination(List<GBeanCreateParam> source) {
    List<List<_IFGenerator>> result = [<_IFGenerator>[]];

    //将所有的参数全必选的选项加入到返回结果中
    result.add(_cloneListParams(source)
        .map((p) => _IFGenerator(p, isSelect: true))
        .toList(growable: true));

    for (int i = 1; i < Math.pow(2, source.length) - 1; i++) {
//      Set<RoutePageParam> eligibleCollections = Set();
      List<_IFGenerator> paras = _cloneListParams(source)
          .map((p) => _IFGenerator(p))
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
        .map((p) => _IFGenerator(p))
        .toList(growable: true));
    return result;
  }

  String _generateBeanConstructorOneParams(
      GBeanCreateParam param, String newBeanCMD, String value) {
//    if (param.isNamed) {
//      return ("beanInstance=$newBeanCMD(${param.keyInFun}:$value);");
//    } else {
//      return ("beanInstance=$newBeanCMD($value);");
//    }
    return _generateBeanConstructorParams(newBeanCMD, [param], [value]);
  }

  String _generateBeanConstructorParams(
      String newBeanCMD, List<GBeanCreateParam> params, List<String> values) {
    if (params.length != values.length)
      throw Exception(
          "_generateBeanConstructorParams params.length!=values.length");

    StringBuffer codeBuffer = StringBuffer();
    codeBuffer.write("beanInstance=$newBeanCMD(");
    for (var i = 0; i < params.length; i++) {
      GBeanCreateParam param = params[i];
      String value = values[i];
      if (param.isNamed) {
        codeBuffer.write("${param.keyInFun}:$value");
      } else {
        codeBuffer.write("$value");
      }

      if (i < params.length - 1) {
        codeBuffer.write(",");
      }
    }
    codeBuffer.write(");");
    return codeBuffer.toString();
  }

  dynamic _generateBeanParamDefValueByDartCoreTypeBase(GBeanCreateParam param) {
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
  GBeanCreateParam param;
  bool isSelect = false;
  List<String> otherContent = [];

  _IFGenerator(this.param, {this.isSelect = false});

  String get whereStr {
    if (!isSelect) return "!mapParam.containsKey('${param.key}')";
    String w = "";
    if ("String" == param.paramType) {
      w = "(mapParam.containsKey('${param.key}') && "
          "(mapParam['${param.key}'] is ${param.paramType} "
          "|| mapParam['${param.key}'] is num || mapParam['${param.key}'] is bool))";
    } else if ("int" == param.paramType) {
      w = "(mapParam.containsKey('${param.key}') && "
          "(mapParam['${param.key}'] is ${param.paramType} || mapParam['${param.key}'] is String))";
    } else if ("double" == param.paramType) {
      w = "(mapParam.containsKey('${param.key}') && "
          "(mapParam['${param.key}'] is ${param.paramType} || mapParam['${param.key}'] is String))";
    } else if ("bool" == param.paramType) {
      w = "(mapParam.containsKey('${param.key}') && "
          "(mapParam['${param.key}'] is ${param.paramType} || mapParam['${param.key}'] is String))";
    } else {
      w = "(mapParam.containsKey('${param.key}') && "
          "(mapParam['${param.key}'] is ${param.paramType}))";
    }
    return w;
  }

  String get contentStr {
    if (!isSelect) return "";
    String c = "";
    if ("String" == param.paramType) {
      c = "mapParam['${param.key}'] is ${param.paramType} ? mapParam['${param.key}'] as ${param.paramType} : mapParam['${param.key}'].toString()";
    } else if ("int" == param.paramType) {
      c = "mapParam['${param.key}'] is ${param.paramType} ? mapParam['${param.key}'] as ${param.paramType} : "
          "(int.parse( mapParam['${param.key}']) )";
    } else if ("double" == param.paramType) {
      c = "mapParam['${param.key}'] is ${param.paramType} ? mapParam['${param.key}'] as ${param.paramType} : "
          "(double.parse( mapParam['${param.key}']) )";
    } else if ("bool" == param.paramType) {
      c = "mapParam['${param.key}'] is ${param.paramType} ? mapParam['${param.key}'] as ${param.paramType} : "
          "('true'==mapParam['${param.key}'] ? true : false )";
    } else {
      c = "mapParam['${param.key}'] as ${param.paramType}";
    }
    return c;
  }

  String get otherContentStr =>
      otherContent.fold("", (i, n) => "$i $n \n").trimRight();

  _IFGenerator clone() {
    _IFGenerator r = _IFGenerator(param, isSelect: isSelect);
    r.otherContent = cloneList(otherContent, (s) => s);
    return r;
  }
}
