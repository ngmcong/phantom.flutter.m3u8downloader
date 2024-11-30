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
                  setState(() => dataDownloadQueues.add(dialogVal));
                }, icon: const Icon(Icons.add, size: 32)),
              ],
            ),
            DataTable(
              columns: [
                DataColumn(label: const Text('Path')),
                DataColumn(label: const Text('Size')),
              ],
              rows: dataDownloadQueues.map((e) => DataRow(cells: [ DataCell(Text("${e.path}")), DataCell(Text("${doubleToString(e.size)} MB")) ])).toList(),
            ),
          ],
        ),
      ),
    );
  }
}