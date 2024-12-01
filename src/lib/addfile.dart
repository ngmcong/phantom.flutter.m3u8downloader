import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:m3u8downloader/dataentities.dart';

String doubleToString(double? value) {
  return NumberFormat("###,###", "en_US").format(value ?? 0);
}

var txtUrl = TextEditingController(text: "https://cdn-nl-11.vkool.club/videos/rr4---sn-ixh7yn7d/hHnRWT8a2mw/beaf61187e7fb8e1aeca6253d30860fe373304289f2f0e206b5b3d270d80f91ad3820a625d17d7f7c9fba6eab661a722afb882b626a63320b78920110f8751372674cbe9f72354667cbfb9abb56ed4ffe2a4cc55d95bd4eb4a045ee85cf4b01e551fb6569674f0b3569063be140fcb460443eba99a7b0ba4babab600f7f776db8b8c0c9238ca7fcbee1fac6b97d86296bfdf5ccb474eede4efedbbfbac57276f21f227d835a6364bca57cc815d9431c13bc6e3e55b4ac358c330994144011be03d20b811af00bd86ae49b82c2ebfda1a1ff3a9837ec1b45a4a18953b9589eace9ef53141aacb69449a959d166bfa0ebdd79f96014a441e3ad8aab7a49e9f57e4e4808fe3d424d81ad35e4faf21212c40ac63cde92e644cf30894dae42c3abccd882dad45607fb67ed897fbb781c4920c625bdde713e49393f661ed17b1fcce9568c50b7619668141e95afb39a4423e1b457a7c5455d92cf06e4cce38d891b5c84df2c5b912193440705b85b1f07d29d87b3a9541f2ba78610ba8a5db03aa10fd27052efe00441bfe9ec33cf1a6a5f74e44cec673f7256c95c525e9a925e6b3d256505de3faf654abe3be5e3a9e1f993ad2799a1434a5ceb7e246a9e1f778cf44185b8b65631485fee6a8e0987581a0bcf6b1676ffb8729981391d664846983125b186c73bc3c8f6f289e757848e1dcb754fb2869b6e9d4ec5072232de6a0f063c80c4bc6587107f8e978519cc49dc36c6af537d164b9c4d065845b60d1bd9f63f7ec6488f186769bbbefc287bcf31af2b58e2150904d019e928bfd82f1c4e19ff5b4804024e548b6f80512e2e061a205ec9619905f1270bd606e10552943f671be672699ad0638298e96c1d326ed9f049468fc371d1299a95cc23cc95549fa44dba8295aa50e0e850f73c57a380f707c031a40a5b97388bc7fd2960e619f996b1356b817c5c876364dfd73581a48e80cbbde873cb710bef988d70d49401f300b6b35b8f6bbc8e8c192fdd3aab82282b31bb2e729370f9a1479fc65bb1636f11220763da7cccf4b3987f68931d567d705fafebe53dc1a6f38a27207fa8ddaaf79b19bfc189d586374f3e2ba48c81f346a1093d1fb4effa584917551e61dbf1ff2117f0f8283d7872dff302558443af38fa782bf04a860c0a837dc0f1a6b7621c18ba73e14450658c11f96a3ea9544016722e7ace1859ea83346aae433bf5440d84a14136ac074db0c42f91dfc80a34b3c5603c671ba84a62ded1fb5c8.mp4");
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
                  Text("${doubleToString(fileSize)} KB"),
                ],
              ),
              TextButton(onPressed: () async {
                  var headUrl = await http.head(Uri.parse(txtUrl.text),
                    headers: <String, String>{
                      'Referer': 'https://phim.vkool8.net/',
                    }
                  );
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