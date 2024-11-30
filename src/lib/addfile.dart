import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:m3u8downloader/dataentities.dart';

String doubleToString(double? value) {
  return NumberFormat("###,###", "en_US").format(value ?? 0);
}

var txtUrl = TextEditingController(text: "https://media.istockphoto.com/id/1827082239/vi/video/ng%C6%B0%E1%BB%9Di-ph%E1%BB%A5-n%E1%BB%AF-vui-v%E1%BA%BB-ng%C3%A3-v%E1%BB%9Bi-c%C3%A1nh-tay-dang-r%E1%BB%99ng-tr%C3%AAn-gi%C6%B0%E1%BB%9Dng-%E1%BB%9F-nh%C3%A0.mp4?s=mp4-640x640-is&k=20&c=nhwJGAyCpnNqDzNLd-C3idzltkJXI1c0cqUFiV2V9-k=");
var txtSaveFilePath = TextEditingController(text: "D:\\test.mp4");
double? fileSize;
Future<DataDownloadQueue?> addFileDialogBuilder(BuildContext context) async {
  return await showDialog<DataDownloadQueue?>(context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Download file info'),
        content: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: const Text('URL:'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: txtUrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Input your url',
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: const Text('Save as:'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: txtSaveFilePath,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Input your url',
                      ),
                    ),
                  ),
                  TextButton(onPressed: () async {
                      String? outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'Save Your File to desired location',
                        fileName: "");
                      txtSaveFilePath.text = outputFile ?? "";
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_browser, size: 32),
                        const Text('...'),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: const Text('File size:'),
                  ),
                  Text("${doubleToString(fileSize)} MB"),
                ],
              ),
              TextButton(onPressed: () async {
                  var headUrl = await http.head(Uri.parse(txtUrl.text));
                  var contentLength = double.parse(headUrl.headers['content-length'] ?? "0");
                  if (contentLength > 0)
                  {
                    contentLength = contentLength / 1024;
                  }
                  setState(() => fileSize = contentLength);
                  if (fileSize != null && fileSize! > 0) {
                    if (!context.mounted) return;
                    Navigator.pop(context, DataDownloadQueue(txtSaveFilePath.text,txtUrl.text,fileSize));
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 32),
                    const Text('Save to queue'),
                  ],
                ),
              ),
            ],
          );
        }),
      );
    },
  );
}