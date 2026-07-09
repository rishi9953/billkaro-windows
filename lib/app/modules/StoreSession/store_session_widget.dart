import 'package:billkaro/app/modules/StoreSession/store_close_dialog.dart';
import 'package:billkaro/app/modules/StoreSession/store_open_dialog.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

enum StoreSessionChipStyle { compact, expanded, sidebar }

class StoreSessionChip extends StatelessWidget {
  const StoreSessionChip({
    super.key,
    this.style = StoreSessionChipStyle.compact,
  });

  final StoreSessionChipStyle style;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StoreSessionController>()) {
      return const SizedBox.shrink();
    }

    final controller = Get.find<StoreSessionController>();
    final loc = AppLocalizations.of(context)!;

    return Obx(() {
      final open = controller.isOpen.value;
      final loading = controller.isLoading.value;

      if (style == StoreSessionChipStyle.expanded) {
        return _buildAppBarChip(
          context: context,
          controller: controller,
          loc: loc,
          open: open,
          loading: loading,
        );
      }

      if (loading && !controller.isActionLoading.value) {
        return _chipShell(
          child: SizedBox(
            width: style == StoreSessionChipStyle.compact ? 72 : 100,
            height: 20,
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }

      final label = open ? loc.store_open : loc.store_closed;
      final bg = open
          ? const Color(0xFF1B7F4B).withOpacity(0.15)
          : const Color(0xFFC62828).withOpacity(0.14);
      final border = open ? const Color(0xFF2E9E62) : const Color(0xFFE53935);
      final dot = open ? const Color(0xFF43D17A) : const Color(0xFFFF6B6B);
      final textColor = open
          ? const Color(0xFF1B7F4B)
          : const Color(0xFFC62828);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context, controller, open),
          borderRadius: BorderRadius.circular(10),
          child: _chipShell(
            background: bg,
            border: border,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    boxShadow: open
                        ? [
                            BoxShadow(
                              color: dot.withOpacity(0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: style == StoreSessionChipStyle.sidebar
                        ? Colors.white
                        : textColor,
                    fontSize: style == StoreSessionChipStyle.expanded ? 13 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                if (style == StoreSessionChipStyle.expanded) ...[
                  const SizedBox(width: 4),
                  Icon(
                    open ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                    size: 14,
                    color: textColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  void _onTap(BuildContext context, StoreSessionController c, bool open) {
    if (open) {
      showStoreCloseDialog(context);
    } else {
      showStoreOpenDialog(context);
    }
  }

  Widget _buildAppBarChip({
    required BuildContext context,
    required StoreSessionController controller,
    required AppLocalizations loc,
    required bool open,
    required bool loading,
  }) {
    final accent = open ? const Color(0xFF4ADE80) : const Color(0xFFFF8A80);
    final session = controller.currentSession.value;
    final timeFmt = DateFormat('hh:mm a');
    final subtitle = open
        ? (session?.openedAt != null
            ? '${loc.opened_at} ${timeFmt.format(session!.openedAt!.toLocal())}'
            : loc.close_store)
        : loc.open_store;

    return Tooltip(
      message: open ? loc.close_store : loc.open_store,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading
              ? null
              : () => _onTap(context, controller, open),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.55), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: loading && !controller.isActionLoading.value
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withOpacity(0.45),
                          ),
                        ),
                        child: Icon(
                          open
                              ? Icons.storefront_rounded
                              : Icons.store_mall_directory_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: open
                                      ? [
                                          BoxShadow(
                                            color: accent.withOpacity(0.7),
                                            blurRadius: 5,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                open ? loc.store_open : loc.store_closed,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.15,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _chipShell({required Widget child, Color? background, Color? border}) {
    final isSidebar = style == StoreSessionChipStyle.sidebar;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: style == StoreSessionChipStyle.compact ? 10 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSidebar
            ? (background ?? Colors.white.withOpacity(0.08))
            : background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSidebar
              ? (border ?? Colors.white24)
              : (border ?? Colors.transparent),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class StoreClosedBanner extends StatelessWidget {
  const StoreClosedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StoreSessionController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<StoreSessionController>();
    final loc = AppLocalizations.of(context)!;

    return Obx(() {
      if (controller.isLoading.value || controller.isOpen.value) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFB71C1C).withOpacity(0.92),
              const Color(0xFFE53935).withOpacity(0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.store_mall_directory_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.store_closed_banner_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.store_closed_banner_subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => showStoreOpenDialog(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFB71C1C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                loc.open_store,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class StoreSessionSidebarInfo extends StatelessWidget {
  const StoreSessionSidebarInfo({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StoreSessionController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<StoreSessionController>();
    final loc = AppLocalizations.of(context)!;
    final timeFmt = DateFormat('hh:mm a');

    return Obx(() {
      final session = controller.currentSession.value;
      final isOpen = controller.isOpen.value && session != null;
      final opened = session?.openedAt != null
          ? timeFmt.format(session!.openedAt!.toLocal())
          : '—';

      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StoreSessionChip(style: StoreSessionChipStyle.sidebar),
            if (isOpen) ...[
              const SizedBox(height: 6),
              Text(
                '${loc.opened_at} $opened',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 11,
                ),
              ),
              if (session.openedByName != null &&
                  session.openedByName!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${loc.opened_by}: ${session.openedByName}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }
}

void showStoreOpenDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const StoreOpenDialog(),
  );
}

void showStoreCloseDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const StoreCloseDialog(),
  );
}
