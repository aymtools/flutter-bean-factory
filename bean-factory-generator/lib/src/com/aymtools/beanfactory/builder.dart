import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generator_bean.dart';
import 'generator_bean_creator.dart';
import 'generator_export_lib.dart';
import 'generator_factory.dart';
import 'generator_factory_init.dart';
import 'generator_factory_scan_lib.dart';
import 'generator_gen_sys_bean_creator.dart';
import 'generator_other_class_template.dart';


Builder initBuilder(BuilderOptions options) =>
    LibraryBuilder(BeanFactoryInitGenerator(),
        generatedExtension: ".init.bf.aymtools.dart");

Builder classTemplateBuilder(BuilderOptions options) =>
    LibraryBuilder(ClassTemplateGenerator(),
        generatedExtension: ".template.aymtools.dart");

Builder scanBeanBuilder(BuilderOptions options) =>
    LibraryBuilder(ScanBeanGenerator(),
        generatedExtension: ".scan.bf.aymtools.dart");

Builder scanLibBeanBuilder(BuilderOptions options) =>
    LibraryBuilder(ScanLibFactoryGenerator(true),
        generatedExtension: ".scan.lib.bf.aymtools.dart");

Builder genSysCreatorBuilder(BuilderOptions options) =>
    LibraryBuilder(GenSysBeanCreatorGenerator(),
        generatedExtension: ".sys.creator.bf.aymtools.dart");

Builder scanCreatorBuilder(BuilderOptions options) =>
    LibraryBuilder(ScanBeanCreatorGenerator(),
        generatedExtension: ".scan.creator.bf.aymtools.dart");

Builder scanLibCreatorBuilder(BuilderOptions options) =>
    LibraryBuilder(ScanLibFactoryGenerator(false),
        generatedExtension: ".scan.lib.creator.bf.aymtools.dart");

Builder beanFactoryBuilder(BuilderOptions options) =>
    LibraryBuilder(BeanFactoryGenerator(), generatedExtension: ".bf.aymtools.dart");

Builder beanFactoryExportBuilder(BuilderOptions options) =>
    LibraryBuilder(ExportLibGenerator(), generatedExtension: ".e.bf.aymtools.dart");
