//import 'dart:async';
//
//import 'package:analyzer/dart/element/element.dart';
//import 'package:bean_factory/bean_factory.dart';
//import 'package:bean_factory_generator/bean_factory_generator.dart';
//import 'package:build/build.dart';
//import 'package:source_gen/source_gen.dart';
//
//import './constants.dart';
//
//final BuildStep _buildStepFactory = null;
//final BuildStep _buildStepExport = null;
//TypeChecker _factoryChecker = TypeChecker.fromRuntime(Factory);
//TypeChecker _exportChecker = TypeChecker.fromRuntime(BeanFactoryLibExport);
//
//class Init extends Builder {
//  @override
//  FutureOr<void> build(BuildStep buildStep) async {
////    if(buildStep.inputId.uri.toString().endsWith('.yaml')){
//    print(
//        "Init  package:${buildStep.inputId.package}  uii:${buildStep.inputId.uri}");
////    }
//    StringBuffer sb = StringBuffer();
//    var lib = await buildStep.resolver
//        .libraryFor(AssetId('color_dart', 'lib/bean_factory.dart'));
//    print(lib.exportedLibraries[0].source.uri);
//  }
//
//  @override
//  Map<String, List<String>> get buildExtensions => {
//        'beanfactory.dart': ['.aymtools.dart']
//      };
//}
//
//class ScanBean_ extends Builder {
//  @override
//  FutureOr<void> build(BuildStep buildStep) async {
//    String pack = buildStep.inputId.package;
//    if (buildStep.inputId.uri.toString().startsWith('asset:') ||
//        buildStep.inputId.uri.toString().endsWith('.aymtools.dart') ||
//        buildStep.inputId.uri.toString().endsWith('beanfactory.dart') ||
//        buildStep.inputId.uri.toString().endsWith('.bf.dart')) return null;
//    if (BeanFactoryGenerator.needScanPackage.contains(pack) ||
//        (BeanFactoryGenerator.needScanPackage.isEmpty &&
//            isNotInNotScanPackage(pack))) {
//      print("ScanBean runing : package:$pack uri: ${buildStep.inputId.uri}");
//      addScannedPackage(pack);
//
//      final resolver = buildStep.resolver;
//      if (!await resolver.isLibrary(buildStep.inputId)) return;
//      final lib = await buildStep.inputLibrary;
//      if (lib.isInSdk) return;
//      _scan(LibraryReader(lib));
//    }
//  }
//
//  @override
//  Map<String, List<String>> get buildExtensions => {
//        '.dart': ['.scan.bf.aymtools.dart']
//      };
//}
//
//class ScanBean extends Generator {
//  String generate(LibraryReader library, BuildStep buildStep) {
//    String pack = buildStep.inputId.package;
//    if (buildStep.inputId.uri.toString().startsWith('asset:') ||
//        buildStep.inputId.uri.toString().endsWith('.aymtools.dart'))
//      return null;
////    if (BeanFactoryGenerator.scanPackage.isEmpty &&
////        notScanPackage.contains(pack)) return null;
////    if (BeanFactoryGenerator.scanPackage.isNotEmpty &&
////        !BeanFactoryGenerator.scanPackage.contains(pack)) return null;
//
//    if (BeanFactoryGenerator.needScanPackage.contains(pack) ||
//        (BeanFactoryGenerator.needScanPackage.isEmpty &&
//            isNotInNotScanPackage(pack))) {
//      print("ScanBean runing : package:$pack uri: ${buildStep.inputId.uri}");
//      addScannedPackage(pack);
//      _scan(library);
//    }
//    return null;
//  }
//}
//
//TypeChecker _beanChecker = TypeChecker.fromRuntime(Bean);
//TypeChecker _beanCreatorChecker = TypeChecker.fromRuntime(BeanCreator);
//
//ScanBeanGenerator scanBean = ScanBeanGenerator();
//ScanBeanCreatorGenerator scanBeanCreator = ScanBeanCreatorGenerator();
//
//_scan(LibraryReader library) {
//  library.annotatedWith(_beanChecker).forEach(
//      (element) => scanBean.parseBean(element.element, element.annotation));
//  library.annotatedWith(_beanCreatorChecker).forEach((element) =>
//      scanBeanCreator.parseBeanCreator(element.element, element.annotation));
//}
//
//BeanFactoryGenerator _beanFactoryG = BeanFactoryGenerator();
//GenSysBeanCreatorGenerator _genSysBeanCreatorCode =
//    GenSysBeanCreatorGenerator();
//
//class GenFactory extends GeneratorForAnnotation<Factory> {
//  static bool flag = false;
//
//  @override
//  Future<void> generateForAnnotatedElement(
//      Element element, ConstantReader annotation, BuildStep buildStep) async {
//    if (flag) return;
//    flag = true;
//    await _parseImportLib(annotation, buildStep);
//    await _genSysBeanCreator(element, buildStep);
//    await _genBeanFactory(element, buildStep);
//    return Future.value();
//  }
//
//  void _parseImportLib(ConstantReader annotation, BuildStep buildStep) async {
//    if (annotation == null ||
//        annotation.peek('otherFactory') == null ||
//        annotation.peek('otherFactory').listValue.isEmpty) return null;
//    await annotation.peek('otherFactory').listValue.forEach((obj) async {
//      try {
//        String libPackageName =
//            obj.toTypeValue().element.librarySource.uri.pathSegments[0];
//        AssetId assetId = AssetId(libPackageName, "lib/$libPackageName.dart");
//        buildStep.canRead(assetId);
//        var lib = await buildStep.resolver.libraryFor(assetId);
//        await lib.exportedLibraries
//            .forEach((element) => _scan(LibraryReader(element)));
//      } catch (e) {
//        print(
//            "Cann't load ${obj.toTypeValue().element.librarySource.uri} library!!");
//      }
//    });
//    ;
//  }
//
//  void _genSysBeanCreator(Element element, BuildStep buildStep) async {
//    await _genSysBeanCreatorCode.genSysCode(buildStep);
//  }
//
//  void _genBeanFactory(Element element, BuildStep buildStep) async {
//    await _beanFactoryG.genBeanFactory(buildStep);
//  }
//}
//
//ExportLibGenerator _exportLib = ExportLibGenerator();
//
//class ExportLib extends GeneratorForAnnotation<BeanFactoryLibExport> {
//  static bool flag = false;
//
//  @override
//  Future<void> generateForAnnotatedElement(
//      Element element, ConstantReader annotation, BuildStep buildStep) async {
//    if (flag) return;
//    flag = true;
//    await _exportLib.exportLib(element, buildStep);
//    return Future.value();
//  }
//}
