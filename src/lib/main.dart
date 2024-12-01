import 'dart:developer';
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
  List<DataDownloadQueue>  dataDownloadQueues = [];
  DataDownloadQueue? downloading;

  void checkDownload() async {
    if (downloading == null && dataDownloadQueues.any((c) => c.status == Status.none))
    {
      downloading = dataDownloadQueues.firstWhere((c) => c.status == Status.none);
      downloadFile();
    }
  }

  void downloadFile() async {
    setState(() {
      downloading!.status = Status.downloading;
    });
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(Uri.parse(downloading!.url!));
    request.headers.set("Referer", 'https://phim.vkool8.net/');
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response, onBytesReceived: (cumulative, total) {
      setState(() {
        downloading!.downloadedSize = cumulative.toDouble() / 1024;
      });
      log("Received $cumulative bytes.");
    });
    var file = File(downloading!.path!);
    log("Downloaded ${bytes.length} bytes.");
    await file.writeAsBytes(bytes);
    setState(() {
      downloading!.status = Status.downloadCompleted;
      checkDownload();
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
                IconButton(onPressed: () async {
                  var dialogVal = await addFileDialogBuilder(context);
                  if (dialogVal == null) return;
                  setState(() {
                    dataDownloadQueues.add(dialogVal);
                    checkDownload();
                  });
                }, icon: const Icon(Icons.add, size: 32)),
              ],
            ),
            DataTable(
              columns: [
                DataColumn(label: const Text('Path')),
                DataColumn(label: const Text('Size')),
                DataColumn(label: const Text('Status')),
                DataColumn(label: const Text('...')),
              ],
              rows: dataDownloadQueues.map((e) => DataRow(cells: [ 
                  DataCell(Text("${e.path}")),
                  DataCell(Text("${doubleToString(e.size)} KB")),
                  DataCell(Text("${e.status}")),
                  DataCell(Text("${doubleToString(e.downloadedSize)}/${doubleToString(e.size)} KB")),
                ]),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}