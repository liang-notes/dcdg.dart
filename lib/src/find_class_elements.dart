import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dcdg/src/class_element_collector.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// Fetch and return the desired class elements from the package
/// rooted at the given path.
Future<Iterable<ClassElement>> findClassElements({
  @required String packagePath,
  bool exportedOnly,
  String searchPath,
}) async {
  String makePackageSubPath(String part0, [String part1]) => path.normalize(
        path.absolute(
          path.join(
            packagePath,
            part0,
            part1,
          ),
        ),
      );

  final contextCollection = AnalysisContextCollection(
    includedPaths: [
      // TODO: Handle other possible directories like web/ and bin/
      makePackageSubPath('lib'),
      makePackageSubPath('lib', 'src'),
    ],
  );

  final dartFiles = Directory(makePackageSubPath(searchPath ?? 'lib'))
      .listSync(recursive: true)
      .where((file) => path.extension(file.path) == '.dart')
      .where((file) => !exportedOnly || !file.path.contains('lib/src/'));

  final collector = ClassElementCollector(
    exportedOnly: exportedOnly,
  );
  for (final file in dartFiles) {
    final filePath = path.normalize(path.absolute(file.path));
    final context = contextCollection.contextFor(filePath);

    final unitResult = await context.currentSession.getResolvedUnit(filePath);
    if (!unitResult.isPart) {
      unitResult.libraryElement.accept(collector);
    }
  }

  return collector.classElements;
}
