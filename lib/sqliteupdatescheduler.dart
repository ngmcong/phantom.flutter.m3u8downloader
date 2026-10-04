import 'dart:async';

import 'package:flutter/foundation.dart';

import 'databasehelper.dart';
import 'dataentities.dart';

class SqliteUpdateScheduler {
  bool _isUpdating = false;
  bool _hasPendingUpdate = false;
  DataDownloadQueue? _latestItem;

  /// Gọi hàm này mỗi khi tiến độ hoặc trạng thái thay đổi
  void scheduleUpdate(DataDownloadQueue item) {
    _latestItem = item; // Luôn giữ tham chiếu đến data mới nhất

    // Nếu chưa có tiến trình ghi nào đang chạy, bắt đầu chạy ngay
    if (!_isUpdating) {
      _processUpdate();
    } else {
      // Nếu SQLite đang bận ghi, chỉ cần đánh dấu để ghi lại sau
      _hasPendingUpdate = true;
    }
  }

  Future<void> _processUpdate() async {
    _isUpdating = true;

    while (_latestItem != null) {
      final itemToUpdate = _latestItem;
      _hasPendingUpdate = false; // Reset cờ trước khi thực thi

      if (itemToUpdate?.id != null) {
        try {
          // Thực hiện ghi vào SQLite
          await DatabaseHelper.instance.updateItem(itemToUpdate!);
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi cập nhật SQLite: $e');
          }
        }
      }

      // Nếu trong lúc chờ ghi DB mà KHÔNG có update mới phát sinh -> Thoát vòng lặp
      if (!_hasPendingUpdate) {
        _latestItem = null;
      }
    }

    _isUpdating = false;
  }
}
