import 'dart:async';
import 'dart:math' as math;
import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';

class VoiceAddMenuItemsBottomSheet extends StatefulWidget {
  const VoiceAddMenuItemsBottomSheet({super.key});

  @override
  State<VoiceAddMenuItemsBottomSheet> createState() =>
      _VoiceAddMenuItemsBottomSheetState();
}

class _VoiceAddMenuItemsBottomSheetState
    extends State<VoiceAddMenuItemsBottomSheet>
    with SingleTickerProviderStateMixin {
  final _helper = _VoiceAddMenuItemsHelperController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _recognizedText = '';

  final List<_VoiceRow> _rows = [];
  bool _isSubmitting = false;
  List<CategoryData> _categories = const [];

  // Animation controller for pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Waveform animation values
  final List<double> _waveHeights = [0.3, 0.6, 0.9, 0.5, 0.7];
  Timer? _waveTimer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Initialize pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
    _loadCategories();
  }

  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 0.2 + (_random.nextDouble() * 0.8);
        }
      });
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    setState(() {
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = 0.2;
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      // Prefer existing MenuItemController cache if available.
      if (Get.isRegistered<MenuItemController>()) {
        final c = Get.find<MenuItemController>();
        if (c.categories.isNotEmpty) {
          _categories = c.categories.toList();
        } else {
          await c.getCategories();
          _categories = c.categories.toList();
        }
      } else {
        final response = await callApi(
          _helper.apiClient.getCategories(_helper.appPref.selectedOutlet!.id!),
          showLoader: false,
        );
        if (response?.status == 'success') {
          _categories = response!.categories.toList();
        }
      }
    } catch (_) {
      // ignore; categories will be empty
    }
  }

  Future<void> _initSpeech() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        _showSnack('Microphone permission is required to use voice input.');
      }
      return;
    }

    _isSpeechAvailable = await _speech.initialize(
      onStatus: (s) {
        // "done" / "notListening" etc
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _isListening = false);
        _stopWaveAnimation();
        final msg = e.errorMsg.toLowerCase();
        if (msg.contains('network') || msg.contains('connection')) {
          _showSnack(
            'Voice input requires an internet connection. '
            'Please check your connection and try again.',
          );
        } else {
          _showSnack('Voice error: ${e.errorMsg}');
        }
      },
    );

    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_isSpeechAvailable) {
      await _initSpeech();
      if (!_isSpeechAvailable) return;
    }

    if (!ConnectivityHelper.instance.isConnected) {
      _showSnack(
        'Voice input requires an internet connection. '
        'Please check your connection and try again.',
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      _stopWaveAnimation();
      _parseIntoRows(_recognizedText);
      return;
    }

    setState(() {
      _recognizedText = '';
      _isListening = true;
    });
    _startWaveAnimation();

    await _speech.listen(
      listenMode: stt.ListenMode.confirmation,
      onResult: (result) {
        if (!mounted) return;
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult) {
          _parseIntoRows(result.recognizedWords);
        }
      },
      partialResults: true,
    );
  }

  void _parseIntoRows(String text) {
    final parsed = _parseMenuItemsFromSpeech(text);
    if (parsed.isEmpty) return;

    setState(() {
      for (final p in parsed) {
        _rows.add(
          _VoiceRow(
            nameController: TextEditingController(text: p.name),
            priceController: TextEditingController(
              text: p.price == null ? '' : p.price!.toStringAsFixed(0),
            ),
            category: p.category ?? 'none',
          ),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_rows.isEmpty) {
      _showSnack('No items to add.');
      return;
    }

    final itemsToAdd = <_ItemWithCategory>[];
    for (final r in _rows) {
      final name = r.nameController.text.trim();
      final price = double.tryParse(r.priceController.text.trim());
      if (name.isEmpty || price == null) continue;
      itemsToAdd.add(
        _ItemWithCategory(name: name, price: price, category: r.category),
      );
    }

    if (itemsToAdd.isEmpty) {
      _showSnack('Please fill item name + price.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final isOnline = _helper.isConnectedToNetwork;

      // ==========================
      // 📴 OFFLINE → SAVE TO SQLITE
      // ==========================
      if (!isOnline) {
        final db = AppDatabase();
        final now = DateTime.now();
        final outletId = _helper.appPref.selectedOutlet!.id!;
        final userId = _helper.appPref.user!.id!;

        final localItems = <ItemData>[];
        for (var i = 0; i < itemsToAdd.length; i++) {
          final item = itemsToAdd[i];
          localItems.add(
            ItemData(
              id: 'temp_${now.millisecondsSinceEpoch}_$i',
              userId: userId,
              outletId: outletId,
              itemName: item.name,
              salePrice: item.price,
              withTax: false,
              gst: 0,
              category: item.category,
              createdAt: now,
              updatedAt: now,
              itemImage: '',
              orderFrom: 'None',
              showItem: true,
            ),
          );
        }

        await db.saveItems(localItems, outletId);

        if (Get.isRegistered<MenuItemController>()) {
          // Reload items from local DB (offline flow in controller)
          await Get.find<MenuItemController>().getItems(showLoader: false);
        }

        if (!mounted) return;
        _showSnack('Added ${itemsToAdd.length} item(s) offline.');
        Navigator.of(context).pop(true);
        return;
      }

      // ==========================
      // 🌐 ONLINE → API + SYNC
      // ==========================
      // Ensure all categories exist (create if missing)
      final uniqueCategories = itemsToAdd.map((i) => i.category).toSet();
      for (final catName in uniqueCategories) {
        if (catName == 'none') continue;
        await _ensureCategoryExists(catName);
      }

      // Add all items via API
      for (final item in itemsToAdd) {
        final request = ItemRequest(
          showItem: true,
          userId: _helper.appPref.user!.id!,
          outletId: _helper.appPref.selectedOutlet!.id!,
          itemName: item.name,
          itemImage: '',
          salePrice: item.price,
          withTax: false,
          gst: 0.0,
          category: item.category,
          orderFrom: 'None',
        );
        // Use the shared callApi helper so offline mode / retry logic
        // behaves the same as the normal add-item flow.
        final response = await callApi(
          _helper.apiClient.addItem(request),
          showLoader: false,
        );
        if (response == null ||
            (response is Map && response['status'] != 'success')) {
          throw Exception(
            (response is Map ? response['message'] : null) ??
                'Failed to add "${item.name}"',
          );
        }
      }

      // Refresh categories and items
      await _loadCategories();
      if (Get.isRegistered<MenuItemController>()) {
        await Get.find<MenuItemController>().getCategories();
        await Get.find<MenuItemController>().getItems(
          showLoader: false,
          forceApiRefresh: true,
        );
      }

      if (!mounted) return;
      _showSnack('Added ${itemsToAdd.length} item(s) successfully.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _ensureCategoryExists(String categoryName) async {
    if (categoryName == 'none') return;

    final normalized = categoryName.toLowerCase().trim();
    // Check if category already exists
    final exists = _categories.any(
      (c) => c.categoryName.toLowerCase() == normalized,
    );
    if (exists) return;

    // Create category
    try {
      final response = await callApi(
        _helper.apiClient.addCategory(_helper.appPref.selectedOutlet!.id!, {
          'userId': _helper.appPref.user!.id,
          'outletId': _helper.appPref.selectedOutlet!.id,
          'categoryName': normalized,
        }),
        showLoader: false,
      );

      if (response != null && response['status'] == 'success') {
        // Reload categories to include the new one
        await _loadCategories();
      }
    } catch (e) {
      debugPrint('Failed to create category "$categoryName": $e');
      // Continue anyway - item will be added with category name
    }
  }

  void _showSnack(String msg) {
    showSuccess(description: msg);
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _pulseController.dispose();
    _waveTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(Get.context!)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Voice: Add Menu Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                // Animated mic button with pulsing effect
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing glow effect when listening
                        if (_isListening)
                          Container(
                                width: 56 * _pulseAnimation.value,
                                height: 56 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(
                                    0.3 *
                                        (1 - (_pulseAnimation.value - 1) / 0.2),
                                  ),
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.red.withOpacity(0.5),
                              ),
                        // Mic button
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isListening
                                ? LinearGradient(
                                    colors: [Colors.red, Colors.red.shade700],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColor.secondaryPrimary,
                                      AppColor.primary,
                                    ],
                                  ),
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : [],
                          ),
                          child: IconButton(
                            tooltip: _isListening ? 'Stop' : 'Start',
                            onPressed: _isSubmitting ? null : _toggleListening,
                            icon: Icon(
                              _isListening ? Icons.stop_circle : Icons.mic,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            // Waveform visualization when listening
            if (_isListening) ...[
              const SizedBox(height: 16),
              _WaveformVisualizer(heights: _waveHeights),
              const SizedBox(height: 8),
              Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.secondaryPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .fadeIn(duration: 800.ms)
                  .then()
                  .fadeOut(duration: 800.ms),
            ],
            if (_recognizedText.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColor.secondaryPrimary.withOpacity(0.1),
                          AppColor.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColor.secondaryPrimary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _recognizedText,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.grey[800],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: -0.1, end: 0, duration: 300.ms),
            ],
            const SizedBox(height: 12),
            if (_rows.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${loc.items} (${_rows.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: _rows.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Tap mic and say e.g. "Tea 15 in Beverages, Coffee 40 category Beverages".\nWe\'ll auto-create rows with categories, you can edit before submit.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final row = _rows[i];
                        return _RowCard(
                              nameController: row.nameController,
                              priceController: row.priceController,
                              category: row.category,
                              onDelete: _isSubmitting
                                  ? null
                                  : () => setState(() {
                                      row.dispose();
                                      _rows.removeAt(i);
                                    }),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (i * 50).ms)
                            .slideX(begin: -0.1, end: 0, duration: 400.ms);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceAddMenuItemsHelperController extends BaseController {}

class _RowCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final String category;
  final VoidCallback? onDelete;

  const _RowCard({
    required this.nameController,
    required this.priceController,
    required this.category,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if (category != 'none') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.secondaryPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColor.secondaryPrimary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColor.secondaryPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.capitalize ?? category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.secondaryPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoiceRow {
  final TextEditingController nameController;
  final TextEditingController priceController;
  String category;

  _VoiceRow({
    required this.nameController,
    required this.priceController,
    required this.category,
  });

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _ParsedMenuItem {
  final String name;
  final double? price;
  final String? category;

  _ParsedMenuItem({required this.name, required this.price, this.category});
}

class _ItemWithCategory {
  final String name;
  final double price;
  final String category;

  _ItemWithCategory({
    required this.name,
    required this.price,
    required this.category,
  });
}

List<_ParsedMenuItem> _parseMenuItemsFromSpeech(String raw) {
  final text = raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return [];

  // Split on "and", comma, or "then"
  final parts = text.split(
    RegExp(r'\s*(?:,| and | then )\s*', caseSensitive: false),
  );

  final out = <_ParsedMenuItem>[];
  for (var p in parts) {
    final s = p.trim();
    if (s.isEmpty) continue;

    // Normalize number-words → digits so "tea fifteen" works.
    var normalized = _normalizeSpokenNumbers(s);

    // Try to extract category first (patterns: "in Category", "category Category", "under Category")
    String? category;
    final categoryPatterns = [
      // Stop capturing category when we hit price-intent words, rupee words, currency, or a digit.
      RegExp(
        r'\b(?:in|category|categories|under|belongs? to)\s+([a-z][a-z\s]+?)(?:\s+(?:for|at|price|rs|rupee|rupees|rupay|rupaye|inr|₹|\d))',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:in|category|categories|under|belongs? to)\s+([a-z][a-z\s]+?)$',
        caseSensitive: false,
      ),
    ];

    for (final pattern in categoryPatterns) {
      final catMatch = pattern.firstMatch(normalized);
      if (catMatch != null) {
        category = _cleanName(catMatch.group(1)!).toLowerCase();
        // Remove category from normalized text for further processing
        normalized = normalized.replaceAll(pattern, ' ').trim();
        break;
      }
    }

    // Extract price at end OR "for/at/price" patterns (supports decimals)
    final m =
        RegExp(r'(\d+(?:\.\d+)?)\s*$').firstMatch(normalized) ??
        RegExp(
          r'\b(?:for|at|price)\s*(\d+(?:\.\d+)?)\b',
          caseSensitive: false,
        ).firstMatch(normalized) ??
        RegExp(
          r'\b(?:rs|rupees|rupee)\s*(\d+(?:\.\d+)?)\b',
          caseSensitive: false,
        ).firstMatch(normalized);
    if (m == null) {
      // No price found → still create row with empty price to let user fill
      final name = _cleanName(normalized);
      if (name.isNotEmpty) {
        out.add(_ParsedMenuItem(name: name, price: null, category: category));
      }
      continue;
    }

    final price = double.tryParse(m.group(1)!);
    // If price matched mid-sentence ("tea for 15"), take text before match.
    final namePart = normalized.substring(0, m.start).trim();
    final name = _cleanName(namePart);
    if (name.isNotEmpty) {
      out.add(_ParsedMenuItem(name: name, price: price, category: category));
    }
  }

  return out;
}

String _normalizeSpokenNumbers(String input) {
  var s = input.toLowerCase();
  s = s.replaceAll('₹', ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // Common phrases to simplify
  s = s.replaceAll(RegExp(r'\brupees?\b'), ' ');
  s = s.replaceAll(RegExp(r'\brs\.?\b'), ' ');
  s = s.replaceAll(RegExp(r'\brupay(e)?\b'), ' ');
  s = s.replaceAll(RegExp(r'\binr\b'), ' ');
  s = s.replaceAll(RegExp(r'\bonly\b'), ' ');

  // Convert simple number-words up to 9999-ish for prices.
  // Examples handled:
  // - "fifteen" -> 15
  // - "one hundred twenty" -> 120
  // - "two hundred and five" -> 205
  // - "one thousand two hundred" -> 1200
  final tokens = s.split(' ');
  final out = <String>[];
  var i = 0;
  while (i < tokens.length) {
    final parsed = _tryParseNumberWords(tokens, i);
    if (parsed != null) {
      out.add(parsed.value.toString());
      i = parsed.nextIndex;
      continue;
    }
    out.add(tokens[i]);
    i++;
  }
  return out.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _NumParse {
  final int value;
  final int nextIndex;
  _NumParse(this.value, this.nextIndex);
}

_NumParse? _tryParseNumberWords(List<String> tokens, int start) {
  final unit = <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };
  final tens = <String, int>{
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  int i = start;
  int total = 0;
  int current = 0;
  bool consumed = false;

  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'and') {
      i++;
      continue;
    }
    if (unit.containsKey(t)) {
      current += unit[t]!;
      consumed = true;
      i++;
      continue;
    }
    if (tens.containsKey(t)) {
      current += tens[t]!;
      consumed = true;
      i++;
      continue;
    }
    if (t == 'hundred') {
      if (!consumed) return null;
      current *= 100;
      i++;
      continue;
    }
    if (t == 'thousand') {
      if (!consumed) return null;
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
      i++;
      continue;
    }
    break;
  }

  if (!consumed) return null;
  total += current;

  // Heuristic: treat only plausible price numbers as conversions.
  if (total < 0 || total > 100000) return null;
  return _NumParse(total, i);
}

String _cleanName(String s) {
  var x = s.toLowerCase();
  x = x.replaceAll(
    RegExp(r'\b(add|item|items|rupees|rupee|rs|for|at|price|of)\b'),
    ' ',
  );
  x = x.replaceAll(RegExp(r'₹'), ' ');
  x = x.replaceAll(RegExp(r'\s+'), ' ').trim();
  // keep original casing-ish by capitalizing first letter only
  if (x.isEmpty) return '';
  return x[0].toUpperCase() + x.substring(1);
}

// Waveform visualization widget
class _WaveformVisualizer extends StatelessWidget {
  final List<double> heights;

  const _WaveformVisualizer({required this.heights});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        heights.length,
        (index) => Container(
          width: 4,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[200],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 50)),
              curve: Curves.easeInOut,
              height: 30 * heights[index],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColor.secondaryPrimary,
                    AppColor.primary.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.secondaryPrimary.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
