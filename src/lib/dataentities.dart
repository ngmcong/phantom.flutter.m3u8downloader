enum Status { none, downloading, downloadCompleted, error }

class DataDownloadQueue {
  String? path;
  String? url;
  double? size;
  Status status = Status.none;
  double downloadedSize = 0;
  String? referer;
  int numberOfOffset = 0;
  int currentOffset = 0;

  DataDownloadQueue(this.path, this.url, this.size, this.referer);

  Map<String, dynamic> toJson() => {'path': path, 'url': url, 'size': size};
}

List<String> validTypes = [
  'application/vnd.apple.mpegurl',
  'application/x-mpegurl',
  'application/x-mpegurl; charset=utf-8',
  'text/html; charset=utf-8',
];
