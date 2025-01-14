enum Status { none, downloading, downloadCompleted }

class DataDownloadQueue {
  String? path;
  String? url;
  double? size;
  Status status = Status.none;
  double downloadedSize = 0;
  String? referer;

  DataDownloadQueue(this.path, this.url, this.size, this.referer);

  Map<String, dynamic> toJson() => {'path': path, 'url': url, 'size': size};
}
