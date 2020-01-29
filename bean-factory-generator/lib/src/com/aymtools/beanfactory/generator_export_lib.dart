import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:bean_factory/bean_factory.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator_factory.dart';

class ExportLibGenerator extends GeneratorForAnnotation<BeanFactoryLibExport> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element.librarySource.uri.toString().endsWith('.bf.aymtools.dart'))
      return null;
    return _parseExportFactory(element.librarySource.uri.toString(), buildStep);
  }

  Future<String> _parseExportFactory(
      String exportBeanFactoryUri, BuildStep buildStep) async {
    String package = buildStep.inputId.package;
    var libExportFile = File('lib/$package.dart');
    if (libExportFile.existsSync()) {
      AssetId assetId = AssetId(package, libExportFile.path);
      var lib = await buildStep.resolver.libraryFor(assetId);
      if (lib != null) {
        String libContent = lib.source.contents.data;
        libContent += _genExportBeanFactory(package, exportBeanFactoryUri, lib);
        libExportFile.writeAsStringSync(libContent);
      } else {
        print("${libExportFile.path} is not lib");
        throw new Exception("${libExportFile.path} is not lib");
      }
    } else {
      String libContent = _genLibName(package) +
          _genExportBeanFactory(package, exportBeanFactoryUri, null);
      libExportFile.writeAsStringSync(libContent);
    }
    return null;
  }

  String _genLibName(package) {
    return "library $package;\n";
  }

  String _genExportBeanFactory(
      String package, String exportBeanUri, LibraryElement lib) {
    List<String> le = lib == null
        ? []
        : lib.exportedLibraries.map((l) => l.source.uri.toString()).toList();
    String result = BeanFactoryGenerator.imports
        .map((i) => i.key)
        .where((i) => "dart:core" != i)
        .where((i) => "package:bean_factory/bean_factory.dart" != i)
//        .where((i) => !i.startsWith("package:flutter"))
        .where((i) => !le.contains(i))
        .where((i) => !i.endsWith(".aym.dart"))
        .where((i) => i != exportBeanUri)
//        .where((i) => i.startsWith("package:$package"))
        .map((i) => "export '${i}';\n")
        .fold("", (i, n) => i + n);
    if (!le.contains(exportBeanUri)) {
      result += "export '${exportBeanUri}';\n";
    }
    return result;
  }
}
