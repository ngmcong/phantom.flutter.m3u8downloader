import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:m3u8downloader/addfile.dart';
import 'package:m3u8downloader/dataentities.dart';

void main() {
  runApp(const M3U8DownloaderApp());
}

class M3U8DownloaderApp extends StatelessWidget {
  const M3U8DownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // appBar: AppBar(title: const Text('MiniSalePOS')),
        body: const M3U8DownloaderView(),
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
            openDialogAndGetData(
              url: requestBody['url'],
              referer: requestBody['initiator'],
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
              columns: [
                DataColumn(label: const Text('Path')),
                DataColumn(label: const Text('Size')),
                DataColumn(label: const Text('Status')),
                DataColumn(label: const Text('...')),
              ],
              rows:
                  dataDownloadQueues
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
