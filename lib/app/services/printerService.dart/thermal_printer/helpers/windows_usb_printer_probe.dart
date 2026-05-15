import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

/// Win32 spooler status flags (winspool.h) that mean the printer cannot accept jobs.
const int _statusOffline = 0x00000080;
const int _statusError = 0x00000002;
const int _statusNotAvailable = 0x00001000;

/// Returns whether Windows reports the named printer as online and reachable.
///
/// On Windows, USB thermal printers are enumerated as installed queue names
/// ([PrinterNames]); the queue stays listed when the device is powered off.
/// [OpenPrinter] + [GetPrinter] status is the reliable signal for offline hardware.
bool isWindowsUsbPrinterReachable(String printerName) {
  final name = printerName.trim();
  if (name.isEmpty) return false;

  final hPrinter = calloc<HANDLE>();
  final namePtr = name.toNativeUtf16();
  try {
    if (OpenPrinter(namePtr, hPrinter, nullptr) == 0) {
      return false;
    }
    final handle = hPrinter.value;

    final pcbNeeded = calloc<DWORD>();
    try {
      GetPrinter(handle, 2, nullptr, 0, pcbNeeded);
      if (pcbNeeded.value == 0) {
        return false;
      }

      final buffer = calloc<Uint8>(pcbNeeded.value);
      final pcbWritten = calloc<DWORD>();
      try {
        if (GetPrinter(handle, 2, buffer, pcbNeeded.value, pcbWritten) == 0) {
          return false;
        }
        final info = buffer.cast<PRINTER_INFO_2>();
        final status = info.ref.Status;
        if ((status & _statusOffline) != 0) return false;
        if ((status & _statusNotAvailable) != 0) return false;
        if ((status & _statusError) != 0) return false;
        return true;
      } finally {
        calloc
          ..free(buffer)
          ..free(pcbWritten);
      }
    } finally {
      calloc.free(pcbNeeded);
      ClosePrinter(handle);
    }
  } catch (e, st) {
    debugPrint('Windows USB printer probe error: $e\n$st');
    return false;
  } finally {
    calloc
      ..free(namePtr)
      ..free(hPrinter);
  }
}
