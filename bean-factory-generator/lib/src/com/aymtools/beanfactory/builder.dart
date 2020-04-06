import 'dart:async';
import 'dart:io';
//import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/constants.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/generator.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/scanner.dart';
import 'package:bean_factory_generator/src/com/aymtools/beanfactory/writer.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator_bean.dart';
import 'generator_bean_creator.dart';
import 'generator_export_lib.dart';
import 'generator_factory.dart';
import 'generator_factory_init.dart';
import 'generator_factory_scan_lib.dart';
import 'generator_factory_gen_sys_code.dart';
import 'generator_other_class_template.dart';

//var _num = 0;
//
//Builder initBuilder(BuilderOptions options) {
//  _num++;
//  print("run number:$_num");
////  if (_num > 1) return null;
//  return LibraryBuilder(BeanFactoryInitGenerator(),
//      generatedExtension: ".init.bf.aymtools.dart");
//}
//
//Builder classTemplateBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(ClassTemplateGenerator(),
//        generatedExtension: ".template.aymtools.dart");
//
//Builder scanBeanBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(ScanBeanGenerator(),
//        generatedExtension: ".scan.bf.aymtools.dart");
//
//Builder scanLibBeanBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(ScanLibFactoryGenerator(true),
//        generatedExtension: ".scan.lib.bf.aymtools.dart");
//
//Builder genSysCreatorBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(GenSysBeanCreatorGenerator(),
//        generatedExtension: ".sys.bf.aymtools.dart");
//
//Builder scanCreatorBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(ScanBeanCreatorGenerator(),
//        generatedExtension: ".scan.creator.bf.aymtools.dart");
//
//Builder scanLibCreatorBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(ScanLibFactoryGenerator(false),
//        generatedExtension: ".scan.lib.creator.bf.aymtools.dart");
//
//Builder beanFactoryBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(BeanFactoryGenerator(),
//        generatedExtension: ".bf.aymtools.dart");
//
//Builder beanFactoryExportBuilder(BuilderOptions options) =>
////    _num > 1
////    ? null
////    :
//    LibraryBuilder(ExportLibGenerator(),
//        generatedExtension: ".e.bf.aymtools.dart");
//

Builder init(BuilderOptions options) => Init();
//PostProcessBuilder init(BuilderOptions options) {
//  print('bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
//  return Init_();
//}

Builder scanBean(BuilderOptions options) => Scan();
//    LibraryBuilder(ScanBean(), generatedExtension: ".scan.bf.aymtools.dart");

Builder beanFactoryExport(BuilderOptions options) => null;
//    LibraryBuilder(ExportLib(), generatedExtension: ".e.bf.aymtools.dart");

Builder beanFactory(BuilderOptions options) => Gen();
//    LibraryBuilder(GenFactory(), generatedExtension: ".bf.aymtools.dart");

class Init extends Builder {
  static TypeChecker _factoryChecker = TypeChecker.fromRuntime(Factory);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    print(
//        "Init  package:${buildStep.inputId.package}  uii:${buildStep.inputId.uri}");
    if (config != null) return;

    String fUri = buildStep.inputId.uri.toString();

    Factory factory;
    if (fUri.endsWith('beanfactory.dart') || fUri.endsWith('bf.dart')) {
      final resolver = buildStep.resolver;
      if (!await resolver.isLibrary(buildStep.inputId)) return;
      final lib = await buildStep.inputLibrary;
      ConstantReader annotation =
          LibraryReader(lib).annotatedWith(_factoryChecker).first?.annotation;
      if (annotation != null) {
        List<String> otherFactory = annotation.peek('otherFactory').isNull ||
                annotation.peek('otherFactory').listValue.isEmpty
            ? []
            : annotation
                .peek('otherFactory')
                .listValue
                .map((e) => e.toTypeValue())
                .map((e) => e.element.librarySource.uri.pathSegments[0])
                .where((element) => element != null && element.isNotEmpty)
                .toList();

        bool isGenFactory = annotation.peek('isGenFactory').isNull ||
                !annotation.peek('isGenFactory').isBool
            ? true
            : annotation.peek('isGenFactory').boolValue;
        bool isGenLibExport = annotation.peek('isGenLibExport').isNull ||
                !annotation.peek('isGenLibExport').isBool
            ? false
            : annotation.peek('isGenLibExport').boolValue;
        List<String> importLibsName =
            annotation.peek('importLibsName').isNull ||
                    !annotation.peek('importLibsName').isList
                ? []
                : annotation
                    .peek('importLibsName')
                    .listValue
                    .map((e) => e.toStringValue())
                    .toList(growable: true);

        importLibsName.addAll(otherFactory);
        factory = Factory(
            importLibsName: importLibsName,
            isGenFactory: isGenFactory,
            isGenLibExport: isGenLibExport);
      }
    }
    if (factory != null) {
      setBeanFactory(factory, buildStep.inputId.uri, buildStep.inputId.package);
      await _init(buildStep);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        'beanfactory.dart': ['.init.bf.aymtools.dart'],
        'bf.dart': ['.init.bf.aymtools.dart']
      };

  Future<void> _init(BuildStep buildStep) async {
    await scanLibrary(buildStep, 'bean_factory');
//    try {
//      AssetId assetId =
//          AssetId('bean_factory', "lib/src/com/aymtools/beanfactory/core.dart");
//      var lib = await buildStep.resolver.libraryFor(assetId);
//      scan(LibraryReader(lib));
//    } catch (e) {
//      print("Cann't load bean_factory library!! \n $e");
//    }
  }
}

class Scan extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    String inputUri = buildStep.inputId.uri.toString();
    if (inputUri.startsWith('package:bean_factory/src/') ||
        inputUri.startsWith('package:bean_factory_generator/src/') ||
        inputUri.startsWith('asset:') ||
        inputUri.endsWith('.aymtools.dart') ||
        inputUri.endsWith('beanfactory.dart')) return null;

    String pack = buildStep.inputId.package;
    if (isNeedScanPackage(pack) ||
        (isNeedScanPackageEmpty() && isNotInNotScanPackage(pack))) {
//      print("Scan Bean runing : package:$pack uri: ${buildStep.inputId.uri}");
      final resolver = buildStep.resolver;
      if (!await resolver.isLibrary(buildStep.inputId)) return;
      final lib = await buildStep.inputLibrary;
      if (lib.isInSdk) return;
      scan(LibraryReader(lib));
      addScannedPackage(pack);
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.scan.bf.aymtools.dart']
      };
}

class Gen extends Builder {
  static bool isGenerated = false;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    print("Gen 1");
    if (config != null) {
//      print("Gen 2");
      await _importLibs(buildStep);
      if (config.isGenLibExport) {
//        print("Gen 3");
        await _exportLib(buildStep);
      }
      if (config.isGenFactory) {
//        print("Gen 4");
        await _genInvokerCreator(buildStep);
//        print("Gen 5");
        await _genFactory(buildStep);
//        print("Gen 61");
      }
      isGenerated = true;
      print("BeanFactory gen success!");
    }
  }

  void _importLibs(BuildStep buildStep) async {
    List<String> otherLibs = config.importLibsName;
    for (String libPackageName in otherLibs) {
      await scanLibrary(buildStep, libPackageName);
//      try {
//        AssetId assetId = AssetId(libPackageName, "lib/$libPackageName.dart");
//        var lib = await buildStep.resolver.libraryFor(assetId);
//        await scanExportedLibrary(lib);
//      } catch (e) {
//        print("Cann't load ${libPackageName} library!! \n $e");
//      }
    }
  }

  void _exportLib(BuildStep buildStep) async {
    String package = runWithPackageName;
    AssetId assetId = AssetId(runWithPackageName, 'lib/$package.dart');
    final resolver = buildStep.resolver;
    LibraryElement lib;
    if (await buildStep.canRead(assetId) && await resolver.isLibrary(assetId)) {
      lib = await resolver.libraryFor(assetId);
    }
//    await buildStep.writeAsString(
//        assetId,
//        writeDartFileFormatter
//            .format(genBeanFactoryExportLibCode(package, lib)));

    var libExportFile = File('lib/$package.dart');
    if (libExportFile.existsSync()) {
      libExportFile.deleteSync();
    }
    await libExportFile.writeAsString(writeDartFileFormatter
        .format(genBeanFactoryExportLibCode(package, lib)));
  }

  void _genInvokerCreator(BuildStep buildStep) async {
    String filePath = buildStep.inputId.path;
    filePath = filePath.substring(0, filePath.lastIndexOf("/"));
    filePath = "$filePath/beanfactory.sys.aymtools.dart";
    await buildStep.writeAsString(
        AssetId(runWithPackageName, filePath),
        writeDartFileFormatter.format(genBeanFactoryInvokerCode()));
//        genBeanFactoryInvokerCode());
  }

  void _genFactory(BuildStep buildStep) async {
    String filePath = buildStep.inputId.path;
    filePath = filePath.substring(0, filePath.lastIndexOf("/"));
    filePath = "$filePath/beanfactory.aymtools.dart";
    await buildStep.writeAsString(AssetId(runWithPackageName, filePath),
        writeDartFileFormatter.format(genBeanFactoryCode()));
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        'beanfactory.dart': [
          '.bf.aymtools.dart',
          '.bf.dart',
          'beanfactory.aymtools.dart',
          'beanfactory.sys.aymtools.dart'
        ]
      };
}
