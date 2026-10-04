enum Status { none, downloading, downloadCompleted, error }

class DataDownloadQueue {
  int? id; // Khóa chính cho SQLite
  String? path;
  String? url;
  double? size;
  Status status = Status.none;
  double downloadedSize = 0;
  String? referer;
  int numberOfOffset = 0;
  int currentOffset = 0;

  // DataDownloadQueue(this.path, this.url, this.size, this.referer);
  DataDownloadQueue({
    this.id,
    this.path,
    this.url,
    this.size,
    this.status = Status.none,
    this.downloadedSize = 0,
    this.referer,
    this.numberOfOffset = 0,
    this.currentOffset = 0,
  });

  Map<String, dynamic> toJson() => {'path': path, 'url': url, 'size': size};

  // Chuyển đối tượng thành Map để ghi vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'url': url,
      'size': size,
      'status': status.name, // Lưu enum dưới dạng String
      'downloadedSize': downloadedSize,
      'referer': referer,
      'numberOfOffset': numberOfOffset,
      'currentOffset': currentOffset,
    };
  }

  // Khôi phục đối tượng từ Map lấy từ SQLite
  factory DataDownloadQueue.fromMap(Map<String, dynamic> map) {
    return DataDownloadQueue(
      id: map['id'] as int?,
      path: map['path'] as String?,
      url: map['url'] as String?,
      size: (map['size'] as num?)?.toDouble(),
      status: Status.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => Status.none,
      ),
      downloadedSize: (map['downloadedSize'] as num?)?.toDouble() ?? 0.0,
      referer: map['referer'] as String?,
      numberOfOffset: map['numberOfOffset'] as int? ?? 0,
      currentOffset: map['currentOffset'] as int? ?? 0,
    );
  }
}

List<String> validTypes = [
  'application/vnd.apple.mpegurl',
  'application/vnd.apple.mpegurl; charset=utf-8',
  'application/x-mpegurl',
  'application/x-mpegurl; charset=utf-8',
  'text/html; charset=utf-8',
  'audio/mpegurl',
  'text/plain',
];
