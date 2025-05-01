import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:m3u8downloader/dataentities.dart';
import 'package:http/http.dart' as http;

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
  String? title,
}) async {
  if (url != null && url.isNotEmpty) {
    txtUrl.text = url;
  }
  var urlParts = url!.split('.');
  var extension = urlParts.take(urlParts.length - 1).last;
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
                    const SizedBox(width: 60, child: Text('URL:')),
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
                    const SizedBox(width: 60, child: Text('Save as:')),
                    Expanded(
                      child: TextField(
                        controller: txtSaveFilePath,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Input your url',
                        ),
                        readOnly: true,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        String? outputFile = await FilePicker.platform.saveFile(
                          dialogTitle: 'Save Your File to desired location',
                          fileName:
                              title == null
                                  ? "video.$extension"
                                  : "$title.$extension",
                        );
                        txtSaveFilePath.text = outputFile ?? "";
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.open_in_browser, size: 32),
                          Text('...'),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('File size:')),
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
                    String headerContent =
                        headUrl.headers['content-type'] ?? "";
                    if (validTypes.contains(headerContent)) {
                      fileSize = 0;
                    }
                    if ((fileSize != null && fileSize! > 0) ||
                        validTypes.contains(headerContent)) {
                      // ignore: use_build_context_synchronously
                      if (!context.mounted) return;
                      Navigator.pop(
                        context,
                        DataDownloadQueue(
                          txtSaveFilePath.text,
                          txtUrl.text,
                          fileSize,
                          referer,
                        ),
                      );
                    }
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 32),
                      Text('Save to queue'),
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
