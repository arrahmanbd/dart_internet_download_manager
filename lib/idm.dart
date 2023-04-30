import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:idm_base/partitions.dart';
import 'package:idm_base/progress.dart';

Future<void> downloader() async {
  print('Input File URL:');
  final url = stdin.readLineSync(encoding: utf8) as String;
  print('Input FileName.format:');
  final filename = stdin.readLineSync(encoding: utf8) as String;
  final numParts = 4;
  final partSize = 1000000; // 1 MB
  final downloadDirectory = Directory('downloads');

//If Not then Create Directory
  if (!downloadDirectory.existsSync()) {
    downloadDirectory.createSync();
  }

//Get File Size to Split
  final response = await http.head(Uri.parse(url));
  final contentLength = int.parse(response.headers['content-length'] ?? '0');

  final parts = calculatePartitions(contentLength, numParts, partSize);

  final futures = <Future>[];

  for (var i = 0; i < numParts; i++) {
    final start = parts[i].start;
    final end = parts[i].end;
    final range = 'bytes=$start-$end';

    final future = http
        .get(Uri.parse(url), headers: {'range': range}).then((response) async {
      final file = File('${downloadDirectory.path}/$filename.part${i + 1}');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      print('Part ${i + 1} downloaded successfully');
    }).catchError((error) {
      print('Error downloading part ${i + 1}: $error');
    });

    futures.add(future);
  }

//Download and Marge with Progress
  final progressBar = ProgressBar(contentLength);
  var downloaded = 0;
  var startTime = DateTime.now();

  await Future.wait(futures).then((_) async {
    final file = File('${downloadDirectory.path}/$filename');
    final sink = file.openWrite(mode: FileMode.writeOnlyAppend);

    for (var i = 0; i < numParts; i++) {
      final partFile = File('${downloadDirectory.path}/$filename.part${i + 1}');
      await sink.addStream(partFile.openRead());
      await partFile.delete();
    }

    sink.flush().then((_) {
      sink.close().then((_) async {
        print('File downloaded successfully');
      });
    });
  }).catchError((error) {
    print('Error combining parts: $error');
  }, test: (error) => error is FileSystemException);

  //Download Speed
  await for (var data in progressBar.data) {
    downloaded += data;
    final percent = (downloaded / contentLength * 100).toStringAsFixed(2);
    final currentTime = DateTime.now();
    final downloadTime = currentTime.difference(startTime).inSeconds;
    final downloadSpeed = (downloaded / downloadTime / 1024).toStringAsFixed(2);
    print('Downloaded $percent%, speed: $downloadSpeed KB/s');
  }
}
