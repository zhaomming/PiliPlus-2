import 'dart:convert';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/utils.dart';

abstract final class UserDataExporter {
  static String exportJson() {
    final Map<String, dynamic> data = {
      'version': 1,
      'app': 'PiliPlus',
      'export_time': DateFormatUtils.format(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        format: DateFormatUtils.longFormatDs,
      ),
      'localWatchLater': GStorage.localWatchLater.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'localFollows': GStorage.localFollows.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'localLikes': GStorage.localLikes.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'localFavorites': GStorage.localFavorites.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'localHistory': GStorage.localHistory.toMap().map((k, v) => MapEntry(k.toString(), v)),
    };
    return Utils.jsonEncoder.convert(data);
  }

  static Future<void> importJson(Map<String, dynamic> map) async {
    final futures = <Future>[];
    if (map['localWatchLater'] case final Map data) {
      futures.add(GStorage.localWatchLater.clear().then((_) => GStorage.localWatchLater.putAll(Map<String, dynamic>.from(data))));
    }
    if (map['localFollows'] case final Map data) {
      futures.add(GStorage.localFollows.clear().then((_) => GStorage.localFollows.putAll(Map<String, dynamic>.from(data))));
    }
    if (map['localLikes'] case final Map data) {
      futures.add(GStorage.localLikes.clear().then((_) => GStorage.localLikes.putAll(Map<String, dynamic>.from(data))));
    }
    if (map['localFavorites'] case final Map data) {
      futures.add(GStorage.localFavorites.clear().then((_) => GStorage.localFavorites.putAll(Map<String, dynamic>.from(data))));
    }
    if (map['localHistory'] case final Map data) {
      futures.add(GStorage.localHistory.clear().then((_) => GStorage.localHistory.putAll(Map<String, dynamic>.from(data))));
    }
    await Future.wait(futures);
  }

  static String exportHtml() {
    final exportTime = DateFormatUtils.format(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      format: DateFormatUtils.longFormatDs,
    );

    final watchLaterMap = GStorage.localWatchLater.toMap();
    final historyMap = GStorage.localHistory.toMap();
    final followsMap = GStorage.localFollows.toMap();
    final favsMap = GStorage.localFavorites.toMap();
    final likesMap = GStorage.localLikes.toMap();

    String buildCards(Map rawMap, {required String type}) {
      if (rawMap.isEmpty) {
        return '<div class="empty">暂无相关数据</div>';
      }
      final buffer = StringBuffer('<div class="grid">');
      for (final entry in rawMap.entries) {
        final val = entry.value;
        if (val is! Map) continue;

        final item = Map<String, dynamic>.from(val);
        final title = _escapeHtml((item['title'] ?? item['uname'] ?? item['name'] ?? '未命名项').toString());
        var cover = (item['pic'] ?? item['cover'] ?? item['face'] ?? item['avatar'] ?? '').toString();
        if (cover.startsWith('//')) {
          cover = 'https:$cover';
        } else if (cover.startsWith('http://')) {
          cover = 'https://${cover.substring(7)}';
        }
        final author = _escapeHtml((item['owner_name'] ?? item['author'] ?? item['uname'] ?? '').toString());
        final time = _escapeHtml((item['add_time'] ?? item['view_time'] ?? (item['view_at'] != null ? DateFormatUtils.format(item['view_at'], format: DateFormatUtils.longFormatDs) : '')).toString());
        final bvid = (item['bvid'] ?? item['id'] ?? '').toString();
        final mid = (item['mid'] ?? '').toString();

        String url = (item['url'] ?? '').toString();
        if (url.isEmpty) {
          if (bvid.startsWith('BV')) {
            url = 'https://www.bilibili.com/video/$bvid';
          } else if (mid.isNotEmpty) {
            url = 'https://space.bilibili.com/$mid';
          }
        }

        buffer.write('''
        <div class="card" data-title="${title.toLowerCase()}" data-author="${author.toLowerCase()}">
          <div class="cover-wrapper">
            ${cover.isNotEmpty ? '<img class="cover" src="${_escapeHtml(cover)}" loading="lazy" referrerpolicy="no-referrer" alt="封面" />' : '<div class="no-cover">无封面</div>'}
          </div>
          <div class="content">
            <h3 class="title" title="$title">$title</h3>
            ${author.isNotEmpty ? '<p class="author">👤 $author</p>' : ''}
            ${time.isNotEmpty ? '<p class="time">🕒 $time</p>' : ''}
            ${url.isNotEmpty ? '<a class="link-btn" href="${_escapeHtml(url)}" target="_blank" rel="noopener noreferrer">在 B 站中打开 ↗</a>' : ''}
          </div>
        </div>
        ''');
      }
      buffer.write('</div>');
      return buffer.toString();
    }

    return '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="referrer" content="no-referrer">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PiliPlus 本地用户数据导出一览</title>
  <style>
    :root {
      --bg-color: #0f172a;
      --card-bg: #1e293b;
      --text-main: #f8fafc;
      --text-sub: #94a3b8;
      --accent: #38bdf8;
      --accent-hover: #0ea5e9;
      --border: #334155;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background-color: var(--bg-color);
      color: var(--text-main);
      padding: 24px 16px;
      line-height: 1.5;
    }
    .header {
      max-width: 1200px;
      margin: 0 auto 20px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border);
    }
    .header h1 { font-size: 24px; color: var(--accent); display: flex; align-items: center; gap: 8px; }
    .header p { color: var(--text-sub); font-size: 14px; margin-top: 6px; }
    .search-bar {
      max-width: 1200px;
      margin: 0 auto 16px;
    }
    .search-input {
      width: 100%;
      background: var(--card-bg);
      border: 1px solid var(--border);
      color: var(--text-main);
      padding: 10px 16px;
      border-radius: 10px;
      font-size: 14px;
      outline: none;
      transition: border-color 0.2s;
    }
    .search-input:focus {
      border-color: var(--accent);
    }
    .nav-tabs {
      max-width: 1200px;
      margin: 0 auto 20px;
      display: flex;
      gap: 8px;
      overflow-x: auto;
      padding-bottom: 6px;
    }
    .tab-btn {
      background: var(--card-bg);
      border: 1px solid var(--border);
      color: var(--text-main);
      padding: 8px 16px;
      border-radius: 20px;
      cursor: pointer;
      font-size: 14px;
      white-space: nowrap;
      transition: all 0.2s;
    }
    .tab-btn.active {
      background: var(--accent);
      color: #0f172a;
      border-color: var(--accent);
      font-weight: 600;
    }
    .container { max-width: 1200px; margin: 0 auto; }
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
      gap: 16px;
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 12px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .card:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 20px rgba(0,0,0,0.3);
    }
    .cover-wrapper {
      position: relative;
      width: 100%;
      padding-top: 56.25%;
      background: #020617;
      overflow: hidden;
    }
    .cover {
      position: absolute;
      top: 0; left: 0; width: 100%; height: 100%;
      object-fit: cover;
    }
    .no-cover {
      position: absolute;
      top: 0; left: 0; width: 100%; height: 100%;
      display: flex; align-items: center; justify-content: center;
      color: var(--text-sub); font-size: 12px;
    }
    .content { padding: 12px; display: flex; flex-direction: column; flex: 1; }
    .title {
      font-size: 14px; font-weight: 600; line-height: 1.4;
      display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
      overflow: hidden; text-overflow: ellipsis; margin-bottom: 8px;
    }
    .author, .time { font-size: 12px; color: var(--text-sub); margin-bottom: 4px; }
    .link-btn {
      margin-top: auto;
      display: inline-block;
      text-align: center;
      background: rgba(56, 189, 248, 0.1);
      color: var(--accent);
      text-decoration: none;
      padding: 6px 12px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 500;
      transition: background 0.2s;
    }
    .link-btn:hover { background: rgba(56, 189, 248, 0.2); }
    .empty { text-align: center; padding: 48px; color: var(--text-sub); font-size: 14px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>📱 PiliPlus 本地用户数据列表</h1>
    <p>导出时间：$exportTime | 本报告脱离客户端后可在任何主流浏览器中独立打开查看并支持即时检索。</p>
  </div>

  <div class="search-bar">
    <input type="text" id="searchInput" class="search-input" placeholder="🔍 快速搜索当前分类下的标题或 UP 主名称..." oninput="filterCards()" />
  </div>

  <div class="nav-tabs">
    <button class="tab-btn active" onclick="switchTab('watchLater', this)">稍后观看 (${watchLaterMap.length})</button>
    <button class="tab-btn" onclick="switchTab('history', this)">播放历史 (${historyMap.length})</button>
    <button class="tab-btn" onclick="switchTab('follows', this)">我的关注 (${followsMap.length})</button>
    <button class="tab-btn" onclick="switchTab('favorites', this)">本地收藏 (${favsMap.length})</button>
    <button class="tab-btn" onclick="switchTab('likes', this)">点赞记录 (${likesMap.length})</button>
  </div>

  <div class="container">
    <div id="watchLater" class="tab-content active">${buildCards(watchLaterMap, type: 'watchLater')}</div>
    <div id="history" class="tab-content">${buildCards(historyMap, type: 'history')}</div>
    <div id="follows" class="tab-content">${buildCards(followsMap, type: 'follows')}</div>
    <div id="favorites" class="tab-content">${buildCards(favsMap, type: 'favorites')}</div>
    <div id="likes" class="tab-content">${buildCards(likesMap, type: 'likes')}</div>
  </div>

  <script>
    function switchTab(id, btn) {
      document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
      document.getElementById(id).classList.add('active');
      btn.classList.add('active');
      filterCards();
    }

    function filterCards() {
      const query = document.getElementById('searchInput').value.trim().toLowerCase();
      const activeTab = document.querySelector('.tab-content.active');
      if (!activeTab) return;
      const cards = activeTab.querySelectorAll('.card');
      cards.forEach(card => {
        const title = card.getAttribute('data-title') || '';
        const author = card.getAttribute('data-author') || '';
        if (!query || title.includes(query) || author.includes(query)) {
          card.style.display = 'flex';
        } else {
          card.style.display = 'none';
        }
      });
    }
  </script>
</body>
</html>
''';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
