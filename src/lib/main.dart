import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:m3u8downloader/addfile.dart';
import 'package:m3u8downloader/dataentities.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as path;

int id = 0;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Streams are created so that app can respond to notification-related events
/// since the plugin is initialised in the `main` function
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

const MethodChannel platform = MethodChannel(
  'dexterx.dev/flutter_local_notifications_example',
);

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

String? selectedNotificationPayload;

/// A notification action which triggers a url launch event
const String urlLaunchActionId = 'id_1';

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

/// Defines a iOS/MacOS notification category for text input actions.
const String darwinNotificationCategoryText = 'textCategory';

/// Defines a iOS/MacOS notification category for plain actions.
const String darwinNotificationCategoryPlain = 'plainCategory';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print(
    'notification(${notificationResponse.id}) action tapped: '
    '${notificationResponse.actionId} with'
    ' payload: ${notificationResponse.payload}',
  );
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
      'notification action tapped with input: ${notificationResponse.input}',
    );
  }
}

Future<void> flutterLocalNotificationInitialize() async {
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      !kIsWeb && Platform.isLinux
          ? null
          : await flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    selectedNotificationPayload =
        notificationAppLaunchDetails!.notificationResponse?.payload;
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          darwinNotificationCategoryText,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.text(
              'text_1',
              'Action 1',
              buttonTitle: 'Send',
              placeholder: 'Placeholder',
            ),
          ],
        ),
        DarwinNotificationCategory(
          darwinNotificationCategoryPlain,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('id_1', 'Action 1'),
            DarwinNotificationAction.plain(
              'id_2',
              'Action 2 (destructive)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
            DarwinNotificationAction.plain(
              navigationActionId,
              'Action 3 (foreground)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'id_4',
              'Action 4 (auth required)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.authenticationRequired,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ];

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        // onDidReceiveLocalNotification:
        //     (int id, String? title, String? body, String? payload) async {
        //   didReceiveLocalNotificationStream.add(
        //     ReceivedNotification(
        //       id: id,
        //       title: title,
        //       body: body,
        //       payload: payload,
        //     ),
        //   );
        // },
        notificationCategories: darwinNotificationCategories,
      );
  final LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(
        defaultActionName: 'Open notification',
        defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
      );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true, // Show alert even when app is foreground
      defaultPresentBadge: true, // Update badge even when app is foreground
      defaultPresentSound: true, // Play sound even when app is foreground
    ),
    linux: initializationSettingsLinux,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (
      NotificationResponse notificationResponse,
    ) {
      switch (notificationResponse.notificationResponseType) {
        case NotificationResponseType.selectedNotification:
          selectNotificationStream.add(notificationResponse.payload);
          break;
        case NotificationResponseType.selectedNotificationAction:
          if (notificationResponse.actionId == navigationActionId) {
            selectNotificationStream.add(notificationResponse.payload);
          }
          break;
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

Future<void> _showNotification(String fileName) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id++,
    'Message',
    'Download $fileName file completed!',
    notificationDetails,
    payload: 'item x',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await flutterLocalNotificationInitialize();
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
      listMedias =
          listData
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

  String validUrl(String baseAddress, String url) {
    int minCheckLength = 50;
    if (url.length > minCheckLength && url.contains('/')) {
      var startUrl = url.substring(0, minCheckLength);
      if (baseAddress.contains(startUrl)) {
        var startIndex = baseAddress.indexOf(startUrl);
        return baseAddress.substring(0, startIndex) + url;
      }
    }
    return "$baseAddress/$url";
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
        var baseAddress = downloading!.url!.substring(
          0,
          downloading!.url!.lastIndexOf('/'),
        );
        if (urlList.any((e) => e.startsWith("https://") == false)) {
          urlList = urlList.map(
            (e) => e.startsWith('https://') ? e : validUrl(baseAddress, e),
          );
        }
        urls.clear();
        urls.addAll(urlList);
        if (listData.contains('#EXT-X-MAP:URI=')) {
          var mapUrl = listData.split('#EXT-X-MAP:URI=')[1].split('"')[1];
          urls.insert(0, validUrl(baseAddress, mapUrl));
        }
      }
    }
    bool isFirstTime = true;
    downloading!.downloadedSize = 0;
    double prvDownloadSize = 0;
    try {
      downloading!.numberOfOffset = urls.length;
      int part = 0;
      for (var url in urls) {
        request = await httpClient.getUrl(Uri.parse(url));
        if (referer != null && referer.isNotEmpty) {
          request.headers.set("Referer", referer);
        }
        var response = await request.close();
        part++;
        var bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (cumulative, total) {
            setState(() {
              downloading!.currentOffset = part;
              downloading!.downloadedSize =
                  prvDownloadSize + cumulative.toDouble() / 1024;
              downloading!.size =
                  downloading!.downloadedSize / part.toDouble() * urls.length;
            });
          },
        );
        if (response.headers['content-type']?.first == 'image/png') {
          bytes = Uint8List.fromList(bytes.skip(1).toList());
        }
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
        _showNotification(path.basenameWithoutExtension(downloading!.path!));
        checkDownload();
      });
    } catch (ex) {
      setState(() {
        downloading!.status = Status.downloadCompleted;
        checkDownload();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ex.toString())));
      }
    }
  }

  void openDialogAndGetData({
    String? url,
    String? referer,
    String? title,
  }) async {
    var dialogVal = await addFileDialogBuilder(
      context,
      url: url,
      referer: referer,
      title: title,
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
              (e) =>
                  e['contenttype'] == 'application/vnd.apple.mpegurl' &&
                  e['url'].toString().contains('master.m3u8') == false,
            )) {
              data = requestBody.firstWhere(
                (e) =>
                    e['contenttype'] == 'application/vnd.apple.mpegurl' &&
                    e['url'].toString().contains('master.m3u8') == false,
              );
            }
            await windowManager.show();
            await windowManager.focus();
            openDialogAndGetData(
              url: data['url'],
              referer: data['initiator'],
              title: data['title'],
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Path')),
                    DataColumn(label: Text('Size')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('...')),
                    DataColumn(label: Text('%')),
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
                                    "${doubleToString(e.downloadedSize)}/${doubleToString(e.size)} KB (${e.currentOffset}/${e.numberOfOffset})",
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${(e.currentOffset / e.numberOfOffset.toDouble()).ceil()}',
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
