import 'dart:mirrors';

import 'package:analyzer/dart/element/element.dart';

import 'package:bean_factory/bean_factory.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step_impl.dart';
import 'package:glob/glob.dart';

import 'entities.dart';
import 'generator_bean.dart';
import 'generator_bean_creator.dart';

class ScanLibFactoryGenerator extends GeneratorForAnnotation<Factory> {
  static ScanBeanCreatorGenerator _beanCreatorGenerator =
      ScanBeanCreatorGenerator();
  static ScanBeanGenerator _beanGenerator = ScanBeanGenerator();

  final bool _isFindBean;

  ScanLibFactoryGenerator(this._isFindBean);

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (annotation == null ||
        annotation.peek('otherFactory') == null ||
        annotation.peek('otherFactory').listValue.isEmpty) return null;
    return _parseImportLibFactory(
        annotation.peek('otherFactory').listValue, buildStep);
  }

  Future<String> _parseImportLibFactory(
      List<DartObject> otherLibBeanFactory, BuildStep buildStep) async {
    otherLibBeanFactory.forEach((obj) async {
      String libPackageName =
          obj.toTypeValue().element.librarySource.uri.pathSegments[0];

      AssetId assetId = AssetId(libPackageName, "lib/$libPackageName.dart");

      try {
        var lib = await buildStep.resolver.libraryFor(assetId);
        await _parseImportLibBeans(lib.exportedLibraries, buildStep);
      } catch (e) {
        print("Cann't load $libPackageName library!!");
      }
    });
    return "";
  }

  _parseImportLibBeans(List<LibraryElement> les, BuildStep buildStep) async {
    await les.map((l) => LibraryReader(l)).forEach((l) async {
      if (_isFindBean) {
        _beanGenerator.generate(l, buildStep);
      } else {
        _beanCreatorGenerator.generate(l, buildStep);
      }
    });
  }
}
