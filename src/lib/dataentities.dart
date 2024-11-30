class DataDownloadQueue
{
  String? path;
  String? url;
  double? size;

  DataDownloadQueue(this.path,this.url,this.size);

  Map<String, dynamic> toJson() => {
    'path': path,
    'url': url,
    'size': size,
  };
}