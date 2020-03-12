import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/code_templates.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/constants.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/entities.dart';
import 'package:mustache4dart/mustache4dart.dart';
import 'dart:math' as Math;

String get sysInvokerCodeUri => beanFactoryInvokerCodeUri;

String get sysInvokerCodeUriAs => getImportAsStr(sysInvokerCodeUri);

String _invokerPTemp = null;

String get _invokerP => _invokerPTemp == null
    ? _invokerPTemp = sysInvokerCodeUriAs.isEmpty ? '' : '$sysInvokerCodeUriAs.'
    : _invokerPTemp;

genBeanFactoryCode() => render(codeTemplate, <String, dynamic>{
      'imports': imports.entries
          .map((item) => {
                'importsPath': "" == item.value
                    ? "import '${item.key}';"
                    : "import '${item.key}' as ${item.value} ;"
              })
          .toList(),
      'createBeanInstanceByCustomCreator': beanCreatorMap.entries.isEmpty
          ? ''
          : beanCreatorMap.entries
              .map((e) =>
                  '  case "${e.value.uri}" : return ${e.value.instantiateCode}().create(namedConstructorInUri,mapParam,objParam);')
              .fold('', (p, e) => p + e),
      'createBeanInstanceBySysCreator': beanMap.entries.isEmpty ||
              beanSysCreatorMap.entries.isEmpty
          ? ''
          : beanSysCreatorMap.entries
              .map((e) =>
                  '  case "${e.value.uri}" : return ${e.value.instantiateCode}().create(namedConstructorInUri,mapParam,objParam);')
              .fold('', (p, e) => p + e),
      'invokeMethods': beanMap.entries.isEmpty
          ? ''
          : beanMap.entries
              .map((e) => e.value)
              .where((e) => e.methods.isNotEmpty)
              .map((e) =>
                  ' case ${e.clsType_} : return ${_invokerP}invoke${e.clsType}Methods(bean, methodName,    params: params);')
              .fold('', (p, e) => p + e),
      'getFields': beanMap.entries.isEmpty
          ? ''
          : beanMap.entries
              .map((e) => e.value)
              .where((e) => e.fields.isNotEmpty)
              .map((e) =>
                  ' case ${e.clsType_} : return ${_invokerP}get${e.clsType}Fields(bean, fieldName);')
              .fold('', (p, e) => p + e),
      'setFields': beanMap.entries.isEmpty
          ? ''
          : beanMap.entries
              .map((e) => e.value)
              .where((e) => e.fields.isNotEmpty)
              .map((e) =>
                  ' case ${e.clsType_} :  ${_invokerP}set${e.clsType}Fields(bean, fieldName, value);break;')
              .fold('', (p, e) => p + e),
      'getAllFields': beanMap.entries.isEmpty
          ? ''
          : beanMap.entries
              .map((e) => e.value)
              .where((e) => e.fields.isNotEmpty)
              .map((e) =>
                  ' case ${e.clsType_} : return ${_invokerP}get${e.clsType}AllFields(bean);')
              .fold('', (p, e) => p + e),
      'setAllFields': beanMap.entries.isEmpty
          ? ''
          : beanMap.entries
              .map((e) => e.value)
              .where((e) => e.fields.isNotEmpty)
              .map((e) =>
                  ' case ${e.clsType_} : ${_invokerP}set${e.clsType}AllFields(bean,values);break;')
              .fold('', (p, e) => p + e),
    });

String genBeanFactoryExportLibCode(
    String packageName, LibraryElement oldContent) {
  String exportBeanFactoryUri = beanFactoryInput.toString();
  String result;
  List<String> le;
  if (oldContent == null) {
    result = 'library $packageName;\n';
    le = [];
  } else {
    String temp = '';
    if (null == oldContent.name || oldContent.name.isEmpty) {
      temp += 'library $packageName;\n';
    }
    temp += oldContent.source.contents.data;
    result = temp;
    le = oldContent.exportedLibraries
        .map((l) => l.source.uri.toString())
        .toList();
  }
  result = imports.entries
      .map((i) => i.key)
      .where((i) => "dart:core" != i)
      .where((i) => "package:bean_factory/bean_factory.dart" != i)
      .where((i) => !le.contains(i))
      .where((i) => !i.endsWith(".aymtools.dart"))
      .where((i) => i != exportBeanFactoryUri)
      .map((i) => "export '${i}';\n")
      .fold(result, (i, n) => i + n);
  if (!le.contains(exportBeanFactoryUri)) {
    result += "export '${exportBeanFactoryUri}';\n";
  }
  return result;
}

genBeanFactoryInvokerCode() {
  String result = imports.entries
      .where((i) => "dart:core" != i.key)
      .map((item) => "" == item.value
          ? "import '${item.key}';"
          : "import '${item.key}' as ${item.value} ;")
      .fold("", (i, n) => i + n);
  beanSysCreatorMap.addAll(beanMap.map((k, v) => MapEntry(
      k,
      GBeanCreator(
        v.uri,
        null,
        null,
        "${v.clsType}SysCreator",
        sysInvokerCodeUri,
        sysInvokerCodeUriAs,
        null,
      ))));
  //'BeanCreator'
  //Creator
  result = beanMap.values
      .map((b) => _genClassCreator(b))
      .fold(result, (i, n) => i + n);
  //Method invoker
  result = beanMap.values
      .where((e) => e.methods.isNotEmpty)
      .map((b) => _genMethodInvoke(b))
      .fold(result, (i, n) => i + n);
  //field get
  result = beanMap.values
      .where((e) => e.fields.isNotEmpty)
      .map((b) => _genFieldGet(b))
      .fold(result, (i, n) => i + n);
  //field set
  result = beanMap.values
      .where((e) => e.fields.isNotEmpty)
      .map((b) => _genFieldSet(b))
      .fold(result, (i, n) => i + n);
  //fields get
  result = beanMap.values
      .where((e) => e.fields.isNotEmpty)
      .map((b) => _genFieldGets(b))
      .fold(result, (i, n) => i + n);
  //fields set
  result = beanMap.values
      .where((e) => e.fields.isNotEmpty)
      .map((b) => _genFieldSets(b))
      .fold(result, (i, n) => i + n);
  return result;
}

String _genClassCreator(GBean bean) {
  return """   
@BeanCreator("${bean.uri}") 
class ${bean.clsType}SysCreator extends BeanCustomCreatorBase<${bean.clsType_}> {
  @override
  ${bean.clsType_} create(
      String namedConstructorInUri, Map<String, dynamic> mapParam, objectParam) {
       ${_generateBeanInstanceSwitchConstructor(bean, 'namedConstructorInUri', 'mapParam', 'objectParam')}
  }
}
    """;
}

String _genMethodInvoke(GBean bean) {
  return """
dynamic invoke${bean.clsType}Methods(${bean.clsType_} bean , String methodName , {Map<String, dynamic> params}){
   ${_generateBeanMethodInvokerSwitch(bean, 'methodName', 'bean', 'params')}
    throw NoSuchMethodException(${bean.clsType_} , methodName);
}
    """;
}

String _genFieldGet(GBean bean) {
  return """
dynamic get${bean.clsType}Fields(${bean.clsType_} bean , String fieldName){
    switch (fieldName) {
        ${bean.fields.map((e) => e.value).map((m) => "case '${m.fieldNameKey}' : return bean.${m.fieldName};").reduce((v, e) => v + e)}
    }
    throw NoSuchFieldException(${bean.clsType_} , fieldName);
}
    """;
}

String _genFieldSet(GBean bean) {
  return """
void set${bean.clsType}Fields(${bean.clsType_} bean , String fieldName , dynamic value){
    switch (fieldName) {
        ${bean.fields.map((e) => e.value).map((m) => "case '${m.fieldNameKey}' : bean.${m.fieldName}=value; break;").reduce((v, e) => v + e)}
    }
    throw NoSuchFieldException(${bean.clsType_} , fieldName);
}
    """;
}

String _genFieldGets(GBean bean) {
  return """
Map<String,dynamic> get${bean.clsType}AllFields(${bean.clsType_} bean){
    Map<String,dynamic> result={};
    ${bean.fields.map((e) => e.value).map((e) => "result['${e.fieldNameKey}']=bean.${e.fieldName};").reduce((v, e) => v + e)}
    return result;
}
    """;
}

String _genFieldSets(GBean bean) {
  return """
void set${bean.clsType}AllFields(${bean.clsType_} bean , Map<String,dynamic> values){
    ${bean.fields.map((e) => e.value).map((e) => "if (values.containsKey('${e.fieldNameKey}')) { set${bean.clsType}Fields(bean,'${e.fieldNameKey}',values['${e.fieldNameKey}']); }").reduce((v, e) => v + e)}
}
    """;
}

////一下是根据不同的参数确定不同的使用不同的构造函数

String _generateBeanInstanceSwitchConstructor(GBean bean,
    String namedConstructorInUri, String paramsMapName, String objParamName) {
  StringBuffer stringBuffer = StringBuffer();
  stringBuffer.writeln("${bean.clsType_} beanInstance;");
  stringBuffer.writeln("  switch ($namedConstructorInUri) {");
  bean.constructors.forEach((pair) {
    GBeanConstructor constructor = pair.value;

    String resultStr = 'beanInstance';

    String newBeanCMD =
        "${bean.clsType_}${'' == constructor.namedConstructor ? '' : '.${constructor.namedConstructor}'}";

    stringBuffer.writeln("    case '${constructor.namedConstructorInUri}' :");
    stringBuffer.writeln("");
    List<String> gpsccnp = _generateBeanSwitchConstructorCheckNumParamsInstance(
            constructor, paramsMapName, objParamName, resultStr, newBeanCMD)
        .where((ifStr) => ifStr != "")
        .toList();
    if (gpsccnp.length > 0) {
      gpsccnp.forEach((s) {
        stringBuffer.writeln("$s else ");
      });

      stringBuffer.writeln("{");
      //当所有条件都不满足时 但路由有无参的构造函数 时使用无参的构造函数来 创建
      if (constructor.params.length == 0 || constructor.canCreateForNoParams) {
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
        codeBuffer
            .write("else if(($objParamName is num)||($objParamName is bool)){");
        codeBuffer.write(_generateBeanConstructorOneParams(
            resultStr, newBeanCMD, param, "$objParamName.toString()"));
        codeBuffer.write("}");
      } else if (param.isTypeDartCoreBase) {
        codeBuffer.write("else if($objParamName is String){");
        if (param.type.dartType.isDartCoreBool) {
          codeBuffer.write(_generateBeanConstructorOneParams(resultStr,
              newBeanCMD, param, "'true'==$objParamName ? true : false"));
        } else if (param.type.dartType.isDartCoreInt) {
          codeBuffer.write(_generateBeanConstructorOneParams(
              resultStr, newBeanCMD, param, "int.tryParse($objParamName)"));
        } else if (param.type.dartType.isDartCoreDouble) {
          codeBuffer.write(_generateBeanConstructorOneParams(
              resultStr, newBeanCMD, param, "double.tryParse($objParamName)"));
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
    codeBuffer.write("if ($paramsMapName != null && $objParamName == null)  {");
    codeBuffer.write(_generateBeanConstructorOneParams(
        resultStr, newBeanCMD, param, paramsMapName));
    codeBuffer.write("}");
    result.add(codeBuffer.toString());

    //同时包含了路径参数和传入的map参数
    codeBuffer.clear();
    codeBuffer.write("if ($paramsMapName != null &&  $objParamName != null && "
        " $paramsMapName != $objParamName && ($objParamName is Map<String, dynamic>))  {");
    codeBuffer.write(_generateBeanConstructorOneParams(
        resultStr, newBeanCMD, param, paramsMapName));
    codeBuffer.write("}");
    result.add(codeBuffer.toString());

    //同时包含了路径参数和传入的map参数
    codeBuffer.clear();
    codeBuffer.write("if ($paramsMapName != null &&  $objParamName != null && "
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
      codeBuffer.write("if ($paramsMapName == null && $objParamName==null) {");
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
      codeBuffer.write("if ($paramsMapName == null && $objParamName==null) {");
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
        "if($paramsMapName!=null) {${generateBeanConstructorOrFunctionParamsForMapSwitch(resultStr, newBeanCMD, constructor.params.map((pair) => pair.value).toList(), paramsMapName)}\n}");
  }
  return result;
}

String _generateBeanMethodInvokerSwitch(
    GBean bean, String methodName, String beanName, String paramsMapName) {
  StringBuffer stringBuffer = StringBuffer();
  stringBuffer.writeln("  switch ($methodName) {");
  bean.methods.map((e) => e.value).forEach((m) {
    stringBuffer.writeln("case '${m.methodNameKey}' : ");
    String ifStr = generateBeanConstructorOrFunctionParamsForMapSwitch(
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

String generateBeanConstructorOrFunctionParamsForMapSwitch(
    String resultStr, String CMD, List<GBeanParam> params, String paramsMapName,
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
      .map((list) => _generateBeanConstructorOrFunctionParamsForMapSwitchIf(
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
            "else ${_generateBeanConstructorOrFunctionParamsForMapSwitchIf(resultStr, CMD, paramsNeed, cmdAfter: cmdAfter)}";
      } else {
        ifsStr += _generateBeanConstructorOrFunctionParamsForMapSwitchIf(
            resultStr, CMD, paramsNeed,
            cmdAfter: cmdAfter);
      }
    }
  }

  return (ifsStr);
}

String _generateBeanConstructorOrFunctionParamsForMapSwitchIf(
    String resultStr, String CMD, List<_IFGenerator> params,
    {List<String> cmdAfter = const []}) {
  BoxThree<String, List<String>, String> bt = params
//        .where((ifg) => ifg.isSelect)
      .map((ifg) => BoxThree(ifg.whereStr, ifg.contentStr, ifg.otherContentStr))
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

String _generateBeanConstructorOrFunctionParams(
    String resultStr, String CMD, List<GBeanParam> params, List<String> values,
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
