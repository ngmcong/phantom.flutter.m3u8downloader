import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:m3u8downloader/dataentities.dart';

String doubleToString(double? value) {
  return NumberFormat("###,###", "en_US").format(value ?? 0);
}

var txtUrl = TextEditingController();
var txtSaveFilePath = TextEditingController();
double? fileSize;
Future<DataDownloadQueue?> addFileDialogBuilder(
  BuildContext context, {
  String? url,
  String? referer,
}) async {
  if (url != null && url.isNotEmpty) {
    txtUrl.text = url;
  }
  return await showDialog<DataDownloadQueue?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Download file info'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(width: 60, child: const Text('URL:')),
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
                    SizedBox(width: 60, child: const Text('Save as:')),
                    Expanded(
                      child: TextField(
                        controller: txtSaveFilePath,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Input your url',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        String? outputFile = await FilePicker.platform.saveFile(
                          dialogTitle: 'Save Your File to desired location',
                          fileName: "",
                        );
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
                    SizedBox(width: 60, child: const Text('File size:')),
                    Text("${doubleToString(fileSize)} KB"),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    var headUrl = await http.head(
                      Uri.parse(txtUrl.text),
                      headers: <String, String>{'Referer': referer ?? ""},
                    );
                    var contentLength = double.parse(
                      headUrl.headers['content-length'] ?? "0",
                    );
                    if (contentLength > 0) {
                      contentLength = contentLength / 1024;
                    }
                    setState(() => fileSize = contentLength);
                    if ('application/vnd.apple.mpegurl' ==
                        headUrl.headers['content-type']) {
                      fileSize = 0;
                    }
                    if ((fileSize != null && fileSize! > 0) ||
                        'application/vnd.apple.mpegurl' ==
                            headUrl.headers['content-type']) {
                      if (!context.mounted) return;
                      Navigator.pop(
                        context,
                        DataDownloadQueue(
                          txtSaveFilePath.text,
                          txtUrl.text,
                          fileSize,
                        ),
                      );
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
          },
        ),
      );
    },
  );
}
