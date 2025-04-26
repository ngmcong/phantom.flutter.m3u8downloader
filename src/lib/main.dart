import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:src/addfile.dart';
import 'package:src/dataentities.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(const M3U8DownloaderApp());
}

class M3U8DownloaderApp extends StatelessWidget {
  const M3U8DownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        // appBar: AppBar(title: const Text('MiniSalePOS')),
        body: M3U8DownloaderView(),
      ),
    );
  }
}

class M3U8DownloaderView extends StatefulWidget {
  const M3U8DownloaderView({super.key});

  @override
  State<M3U8DownloaderView> createState() => M3U8DownloaderAppState();
}

class M3U8DownloaderAppState extends State<M3U8DownloaderView> {
  List<DataDownloadQueue> dataDownloadQueues = [];
  DataDownloadQueue? downloading;

  void checkDownload() async {
    if ((downloading == null ||
            downloading?.status == Status.downloadCompleted) &&
        dataDownloadQueues.any((c) => c.status == Status.none)) {
      downloading = dataDownloadQueues.firstWhere(
        (c) => c.status == Status.none,
      );
      downloadFile();
    }
  }

  Future<String> getMediaFromList(
    String listData,
    HttpClient httpClient,
    HttpClientRequest request,
    String? referer,
  ) async {
    if (listData.contains('RESOLUTION=')) {
      var listMedias =
          listData.split('\n').where((e) => e.contains("RESOLUTION=")).toList();
      var intRegex = RegExp(r'RESOLUTION=(\d+x\d+)', multiLine: false);
      String maxRegValue = '';
      String currentMaxLineValue = '';
      for (var media in listMedias) {
        var matches = intRegex.allMatches(media).map((m) => m.group(1));
        var math = matches.first ?? '';
        var testArray = [maxRegValue, math];
        testArray.sort();
        if (testArray[1] == math) {
          maxRegValue = math;
          currentMaxLineValue = media;
        }
      }
      listMedias = listData
          .split('\n')
          .where(
            (e) => e.startsWith("https://") || e.contains("RESOLUTION="),
          )
          .toList();
      var indexLine = listMedias.indexOf(currentMaxLineValue);
      request = await httpClient.getUrl(Uri.parse(listMedias[indexLine + 1]));
      if (referer != null && referer.isNotEmpty) {
        request.headers.set("Referer", referer);
      }
      var response = await request.close();
      return await response.transform(utf8.decoder).join();
    }
    return listData;
  }

  void downloadFile({String? referer}) async {
    setState(() {
      downloading!.status = Status.downloading;
    });
    if (referer == null || referer.isEmpty) referer = downloading!.referer;
    List<String> urls = [downloading!.url!];
    var httpClient = HttpClient();
    HttpClientRequest request;
    if (downloading!.size == 0) {
      request = await httpClient.getUrl(Uri.parse(downloading!.url!));
      if (referer != null && referer.isNotEmpty) {
        request.headers.set("Referer", referer);
      }
      var response = await request.close();
      String headerContent = response.headers['content-type']?.first ?? "";
      if (validTypes.contains(headerContent)) {
        var listData = await response.transform(utf8.decoder).join();
        listData = await getMediaFromList(
          listData,
          httpClient,
          request,
          referer,
        );
        var urlList = listData
            .split('\n')
            .where((e) => e.startsWith('#EXT') == false && e.isNotEmpty);
        if (urlList.any((e) => e.startsWith("https://") == false)) {
          var baseAddress = downloading!.url!.substring(
            0,
            downloading!.url!.lastIndexOf('/'),
          );
          urlList = urlList.map(
            (e) => e.startsWith('https://') ? e : "$baseAddress/$e",
          );
        }
        urls.clear();
        urls.addAll(urlList);
      }
    }
    bool isFirstTime = true;
    downloading!.downloadedSize = 0;
    double prvDownloadSize = 0;
    try {
      for (var url in urls) {
        request = await httpClient.getUrl(Uri.parse(url));
        if (referer != null && referer.isNotEmpty) {
          request.headers.set("Referer", referer);
        }
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (cumulative, total) {
            setState(() {
              downloading!.downloadedSize =
                  prvDownloadSize + cumulative.toDouble() / 1024;
            });
          },
        );
        // if (response.headers['content-type']?.first == 'image/png') {
        //   bytes = Uint8List.fromList(bytes.skip(1).toList());
        // }
        var file = File(downloading!.path!);
        prvDownloadSize += bytes.length / 1024;
        await file.writeAsBytes(
          bytes,
          mode: isFirstTime ? FileMode.write : FileMode.append,
        );
        isFirstTime = false;
      }
      setState(() {
        downloading!.status = Status.downloadCompleted;
        checkDownload();
      });
    } catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ex.toString())));
      }
    }
  }

  void openDialogAndGetData({String? url, String? referer}) async {
    var dialogVal = await addFileDialogBuilder(
      context,
      url: url,
      referer: referer,
    );
    if (dialogVal == null) return;
    setState(() {
      dataDownloadQueues.add(dialogVal);
      checkDownload();
    });
  }

  @override
  void initState() {
    super.initState();
    HttpServer.bind('127.0.0.1', 60024).then((HttpServer server) {
      server.listen((request) async {
        switch (request.method) {
          case 'GET':
            break;
          case 'POST':
            var requestBody = jsonDecode(
              String.fromCharCodes(await request.first),
            );
            var data = requestBody.last;
            if (requestBody.any(
                (e) => e['contenttype'] == 'application/vnd.apple.mpegurl')) {
              data = requestBody.firstWhere(
                (e) => e['contenttype'] == 'application/vnd.apple.mpegurl',
              );
            }
            await windowManager.focus();
            openDialogAndGetData(
              url: data['url'],
              referer: data['initiator'],
            );
            break;
          default:
            request.response.statusCode = HttpStatus.methodNotAllowed;
            request.response.close();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    openDialogAndGetData();
                  },
                  icon: const Icon(Icons.add, size: 32),
                ),
              ],
            ),
            DataTable(
              columns: const [
                DataColumn(label: Text('Path')),
                DataColumn(label: Text('Size')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('...')),
              ],
              rows: dataDownloadQueues
                  .map(
                    (e) => DataRow(
                      cells: [
                        DataCell(Text("${e.path}")),
                        DataCell(Text("${doubleToString(e.size)} KB")),
                        DataCell(Text("${e.status}")),
                        DataCell(
                          Text(
                            "${doubleToString(e.downloadedSize)}/${doubleToString(e.size)} KB",
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
