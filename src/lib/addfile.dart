import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:m3u8downloader/dataentities.dart';
import 'package:http/http.dart' as http;

String doubleToString(double? value) {
  return NumberFormat("###,###", "en_US").format(value ?? 0);
}

String stringBase64Decode(String? value) {
  if (value == null || value.isEmpty) return "";
  // Decode the Base64 string to a List<int> (bytes)
  List<int> decodedBytes = base64Decode(value);

  // Convert the bytes to a UTF-8 string (most common encoding)
  String decodedString = utf8.decode(decodedBytes);
  return decodedString;
}

var txtUrl = TextEditingController();
var txtSaveFilePath = TextEditingController();
double? fileSize;
List<String?>? filterTitle;
final FocusNode _textFieldFocusNode = FocusNode();

Future<DataDownloadQueue?> addFileDialogBuilder(
  BuildContext context, {
  String? url,
  String? referer,
  String? title,
  String? tag,
}) async {
  if (url != null && url.isNotEmpty) {
    txtUrl.text = url;
  }
  txtSaveFilePath.text = '';
  var extension = '';
  var urlParts = url?.split('.');
  if (urlParts?.isNotEmpty == true) {
    if (urlParts!.last == "m3u8") {
      urlParts = urlParts.take(urlParts.length - 1).toList();
    }
    extension = ".${urlParts.last}";
  }
  if (extension != ".mp4") {
    extension = "";
  }
  File file = File('/Users/phantom/Downloads/filtertitlefilenames.txt');
  if (filterTitle == null && file.existsSync()) {
    filterTitle ??= file.readAsStringSync().split('\n');
  }
  if (title != null && title.isNotEmpty) {
    for (var filter in filterTitle!) {
      if (title!.contains(filter!)) {
        title = title.replaceAll(filter, "");
      }
    }
    RegExp pattern = RegExp(r'\[([A-Z]*-\d*)\]*');
    Match? match = pattern.firstMatch(title!);
    String? extractedCode = match?.group(1);
    if (tag?.isNotEmpty == true && extractedCode?.isNotEmpty != true) {
      pattern = RegExp(r'tag=(\w*-\d{3,})*');
      match = pattern.firstMatch(tag!);
      extractedCode = match?.group(1)!;
    }
    if (kDebugMode) {
      print('found in tag $tag: $extractedCode');
    }
    if (extractedCode?.isNotEmpty == true) {
      title = extractedCode;
      extension = ".ts";
    }
  }
  return await showDialog<DataDownloadQueue?>(
    context: context,
    builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_textFieldFocusNode);
      });
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
                        focusNode: _textFieldFocusNode, // Ensure this is here
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
                          hintText: 'Input file path',
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
                                  ? "video$extension"
                                  : "$title$extension",
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
                    if (txtSaveFilePath.text.isEmpty) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select your save file'),
                        ),
                      );
                      return;
                    }
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
