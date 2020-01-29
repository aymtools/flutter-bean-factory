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

var _num = 0;

Builder initBuilder(BuilderOptions options) {
  _num++;
  print("run number:$_num");
  if (_num > 1) return null;
  return LibraryBuilder(BeanFactoryInitGenerator(),
      generatedExtension: ".init.bf.aymtools.dart");
}

Builder classTemplateBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(ClassTemplateGenerator(),
        generatedExtension: ".template.aymtools.dart");

Builder scanBeanBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(ScanBeanGenerator(),
        generatedExtension: ".scan.bf.aymtools.dart");

Builder scanLibBeanBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(ScanLibFactoryGenerator(true),
        generatedExtension: ".scan.lib.bf.aymtools.dart");

Builder genSysCreatorBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(GenSysBeanCreatorGenerator(),
        generatedExtension: ".sys.bf.aymtools.dart");

Builder scanCreatorBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(ScanBeanCreatorGenerator(),
        generatedExtension: ".scan.creator.bf.aymtools.dart");

Builder scanLibCreatorBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(ScanLibFactoryGenerator(false),
        generatedExtension: ".scan.lib.creator.bf.aymtools.dart");

Builder beanFactoryBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(BeanFactoryGenerator(),
        generatedExtension: ".bf.aymtools.dart");

Builder beanFactoryExportBuilder(BuilderOptions options) => _num > 1
    ? null
    : LibraryBuilder(ExportLibGenerator(),
        generatedExtension: ".e.bf.aymtools.dart");
