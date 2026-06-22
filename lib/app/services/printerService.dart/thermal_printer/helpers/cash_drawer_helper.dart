import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// RJ11 POS cash drawers connect to the thermal printer DK port.
/// Opening is done by sending an ESC/POS drawer-kick command through the bill printer.
enum CashDrawerPin { pin2, pin5 }

CashDrawerPin cashDrawerPinFromStorage(String? key) {
  return key == 'pin5' ? CashDrawerPin.pin5 : CashDrawerPin.pin2;
}

String cashDrawerPinStorageKey(CashDrawerPin pin) {
  return pin == CashDrawerPin.pin5 ? 'pin5' : 'pin2';
}

class CashDrawerHelper {
  static Future<List<int>> buildKickBytes(CashDrawerPin pin) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final posPin = pin == CashDrawerPin.pin5 ? PosDrawer.pin5 : PosDrawer.pin2;
    return generator.drawer(pin: posPin);
  }
}
