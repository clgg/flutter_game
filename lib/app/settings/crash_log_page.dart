import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/crash_log_service.dart';

class CrashLogPage extends StatefulWidget {
  const CrashLogPage({super.key});

  @override
  State<CrashLogPage> createState() => _CrashLogPageState();
}

class _CrashLogPageState extends State<CrashLogPage> {
  late Future<List<CrashLogEntry>> _logsFuture;
  CrashLogEntry? _selected;
  String _content = '';
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _logsFuture = CrashLogService.instance.listLogs();
  }

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final strings = _CrashLogStrings.of(context);
    return Scaffold(
      backgroundColor: gameTheme.background,
      appBar: AppBar(
        title: Text(strings.title),
        actions: [
          IconButton(
            tooltip: strings.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<CrashLogEntry>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            final logs = snapshot.data ?? const <CrashLogEntry>[];
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (logs.isEmpty) {
              return _EmptyCrashLogs(onRefresh: _refresh, strings: strings);
            }
            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _CrashLogTile(
                        entry: log,
                        selected: _selected?.path == log.path,
                        strings: strings,
                        onTap: () => _selectLog(log),
                      );
                    },
                  ),
                ),
                Divider(color: gameTheme.line, height: 1),
                Expanded(
                  child: _CrashLogContent(
                    selected: _selected,
                    content: _content,
                    isLoading: _isLoadingContent,
                    strings: strings,
                  ),
                ),
                if (_selected != null)
                  _CrashLogActions(
                    strings: strings,
                    onCopy: _copySelected,
                    onShare: _shareSelected,
                    onDelete: _deleteSelected,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _refresh() {
    setState(() {
      _logsFuture = CrashLogService.instance.listLogs();
    });
  }

  Future<void> _selectLog(CrashLogEntry entry) async {
    setState(() {
      _selected = entry;
      _content = '';
      _isLoadingContent = true;
    });
    final content = await CrashLogService.instance.readLog(entry.path);
    if (!mounted) {
      return;
    }
    setState(() {
      _content = content;
      _isLoadingContent = false;
    });
  }

  Future<void> _copySelected() async {
    if (_content.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_CrashLogStrings.of(context).copied)),
    );
  }

  Future<void> _shareSelected() async {
    final selected = _selected;
    if (selected == null) {
      return;
    }
    try {
      await CrashLogService.instance.shareLog(selected.path);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      final strings = _CrashLogStrings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? strings.shareFailed)),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final selected = _selected;
    if (selected == null) {
      return;
    }
    await CrashLogService.instance.deleteLog(selected.path);
    if (!mounted) {
      return;
    }
    setState(() {
      _selected = null;
      _content = '';
      _logsFuture = CrashLogService.instance.listLogs();
    });
  }
}

class _EmptyCrashLogs extends StatelessWidget {
  const _EmptyCrashLogs({required this.onRefresh, required this.strings});

  final VoidCallback onRefresh;
  final _CrashLogStrings strings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: gameTheme.muted, size: 42),
            const SizedBox(height: 12),
            Text(
              strings.emptyTitle,
              style: TextStyle(
                color: gameTheme.foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: gameTheme.muted, height: 1.35),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(strings.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrashLogTile extends StatelessWidget {
  const _CrashLogTile({
    required this.entry,
    required this.selected,
    required this.strings,
    required this.onTap,
  });

  final CrashLogEntry entry;
  final bool selected;
  final _CrashLogStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? gameTheme.accent : gameTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.bug_report_rounded,
                color: selected ? gameTheme.accent : gameTheme.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: gameTheme.foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatTime(entry.modifiedAt)} · ${entry.bytes} ${strings.bytes}',
                      style: TextStyle(color: gameTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}

class _CrashLogContent extends StatelessWidget {
  const _CrashLogContent({
    required this.selected,
    required this.content,
    required this.isLoading,
    required this.strings,
  });

  final CrashLogEntry? selected;
  final String content;
  final bool isLoading;
  final _CrashLogStrings strings;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    if (selected == null) {
      return Center(
        child: Text(
          strings.selectHint,
          style: TextStyle(color: gameTheme.muted),
        ),
      );
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        content.isEmpty ? strings.emptyFile : content,
        style: TextStyle(
          color: gameTheme.foreground,
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}

class _CrashLogActions extends StatelessWidget {
  const _CrashLogActions({
    required this.strings,
    required this.onCopy,
    required this.onShare,
    required this.onDelete,
  });

  final _CrashLogStrings strings;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          border: Border(top: BorderSide(color: gameTheme.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(strings.copy),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(strings.shareFile),
              ),
            ),
            IconButton(
              tooltip: strings.delete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrashLogStrings {
  const _CrashLogStrings(this.isZh);

  static _CrashLogStrings of(BuildContext context) {
    return _CrashLogStrings(
        Localizations.localeOf(context).languageCode == 'zh');
  }

  final bool isZh;

  String get title => isZh ? '崩溃日志' : 'Crash Logs';
  String get refresh => isZh ? '刷新' : 'Refresh';
  String get copied => isZh ? '崩溃日志已复制' : 'Crash log copied';
  String get shareFailed => isZh ? '无法分享文件' : 'Unable to share file';
  String get emptyTitle => isZh ? '暂无崩溃日志' : 'No crash logs yet';
  String get emptyMessage => isZh
      ? 'Flutter、Dart Zone 和 Android 原生崩溃发生后会保存在这里。'
      : 'Flutter, Dart Zone, and Android native fatal crashes will be saved here after they occur.';
  String get bytes => isZh ? '字节' : 'bytes';
  String get selectHint => isZh ? '选择一条日志查看详情' : 'Select a log to view details';
  String get emptyFile =>
      isZh ? '日志文件为空或不存在。' : 'Log file is empty or missing.';
  String get copy => isZh ? '复制' : 'Copy';
  String get shareFile => isZh ? '分享文件' : 'Share File';
  String get delete => isZh ? '删除' : 'Delete';
}
