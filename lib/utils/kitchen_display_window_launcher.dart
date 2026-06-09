import 'dart:io';

import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:win32/win32.dart';

/// Opens Kitchen Display in a dedicated OS window (Windows only).
/// Only one KDS window is allowed at a time.
class KitchenDisplayWindowLauncher {
  static const kitchenDisplayArg = '--kitchen-display';

  static File get _lockFile =>
      File('${Directory.systemTemp.path}${Platform.pathSeparator}billkaro_kds_window.pid');

  static bool _openInProgress = false;

  static bool isKitchenDisplayLaunch(List<String> args) {
    return args.contains(kitchenDisplayArg);
  }

  /// If another KDS process is already running, focus it and return true.
  static Future<bool> shouldAbortDuplicateLaunch() async {
    if (kIsWeb || !Platform.isWindows) return false;

    final lockPid = _readLockPid();
    if (lockPid == null) return false;

    final myPid = _currentProcessId();
    if (lockPid == myPid) return false;

    if (!await isKdsProcessRunning(lockPid)) {
      _clearLock();
      return false;
    }

    await focusWindow(lockPid);
    return true;
  }

  /// Called when the KDS window is ready (after [appWindow.show]).
  static void registerRunningInstance() {
    if (kIsWeb || !Platform.isWindows) return;
    _writeLockPid(_currentProcessId());
  }

  static Future<void> open() async {
    if (kIsWeb || !Platform.isWindows) {
      Modular.to.navigate(HomeMainRoutes.kitchenDisplay);
      return;
    }

    if (_openInProgress) return;
    _openInProgress = true;
    try {
      final existingPid = _readLockPid();
      if (existingPid != null && await isKdsProcessRunning(existingPid)) {
        await focusWindow(existingPid);
        return;
      }
      _clearLock();

      await Process.start(
        Platform.resolvedExecutable,
        const [kitchenDisplayArg],
        mode: ProcessStartMode.detached,
      );
    } catch (e) {
      debugPrint('Failed to open kitchen display window: $e');
      Modular.to.navigate(HomeMainRoutes.kitchenDisplay);
    } finally {
      _openInProgress = false;
    }
  }

  /// Call when the KDS window closes so the next open can spawn again.
  static void releaseLock() {
    _clearLock();
  }

  /// Removes a lock left from a crashed/closed KDS or a non-KDS process PID.
  static Future<void> clearStaleLockIfNeeded() async {
    final lockPid = _readLockPid();
    if (lockPid == null) return;
    if (!await isKdsProcessRunning(lockPid)) {
      _clearLock();
    }
  }

  /// True when [pid] is a live `billkaro_windows` process started with KDS args.
  static Future<bool> isKdsProcessRunning(int pid) async {
    if (pid <= 0 || !Platform.isWindows) return false;
    if (!await _isProcessRunning(pid)) return false;
    return _processCommandLineContainsKdsArg(pid);
  }

  static int _currentProcessId() => GetCurrentProcessId();

  static Future<bool> _isProcessRunning(int pid) async {
    try {
      final result = await Process.run(
        'tasklist',
        ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH'],
        runInShell: true,
      );
      final out = result.stdout.toString().trim();
      if (out.isEmpty || out.toLowerCase().contains('no tasks')) {
        return false;
      }
      final match = RegExp(r'"[^"]*","(\d+)"').firstMatch(out);
      return match != null && int.tryParse(match.group(1) ?? '') == pid;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _processCommandLineContainsKdsArg(int pid) async {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          '(Get-CimInstance Win32_Process -Filter "ProcessId = $pid").CommandLine',
        ],
        runInShell: true,
      );
      return result.stdout.toString().contains(kitchenDisplayArg);
    } catch (_) {
      return false;
    }
  }

  static Future<void> focusWindow(int pid) async {
    if (!Platform.isWindows || pid <= 0) return;

    try {
      final script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class BillkaroKdsWin32 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
}
"@
\$p = Get-Process -Id $pid -ErrorAction SilentlyContinue
if (\$p -and \$p.MainWindowHandle -ne [IntPtr]::Zero) {
  [BillkaroKdsWin32]::ShowWindow(\$p.MainWindowHandle, 9) | Out-Null
  [BillkaroKdsWin32]::SetForegroundWindow(\$p.MainWindowHandle) | Out-Null
}
''';
      await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('Failed to focus kitchen display window: $e');
    }
  }

  static int? _readLockPid() {
    try {
      if (!_lockFile.existsSync()) return null;
      return int.tryParse(_lockFile.readAsStringSync().trim());
    } catch (_) {
      return null;
    }
  }

  static void _writeLockPid(int pid) {
    try {
      _lockFile.writeAsStringSync('$pid', flush: true);
    } catch (e) {
      debugPrint('Failed to write KDS lock file: $e');
    }
  }

  static void _clearLock() {
    try {
      if (_lockFile.existsSync()) _lockFile.deleteSync();
    } catch (_) {}
  }
}
