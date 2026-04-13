import 'package:billkaro/app/modules/Reports/reports_controller.dart';
import 'package:billkaro/config/config.dart';

class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final ReportsController controller = Get.put(ReportsController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final scrollPhysics = isWindows
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        title: Text(
          loc.reports,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Scrollbar(
          thumbVisibility: isWindows,
          child: SingleChildScrollView(
            physics: scrollPhysics,
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, loc),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 760;
                        final tileWidth = twoColumns
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: tileWidth,
                              child: _ReportCard(
                                icon: Icons.receipt_long,
                                iconColor: AppColor.primary,
                                title: loc.order_Reports,
                                subtitle: 'View and analyze order details',
                                onTap: controller.navigateToOrderReports,
                                enableHover: isWindows,
                              ),
                            ),
                            SizedBox(
                              width: tileWidth,
                              child: _ReportCard(
                                icon: Icons.inventory_2,
                                iconColor: const Color(0xFF10B981),
                                title: loc.item_Reports,
                                subtitle: 'View and analyze item sales',
                                onTap: controller.navigateToItemReports,
                                enableHover: isWindows,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.reports,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Access detailed reports and insights',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enableHover;

  const _ReportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enableHover,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hovered = widget.enableHover && _hovered;
    final baseShadowOpacity = hovered ? 0.08 : 0.04;
    final borderColor = hovered
        ? Colors.black.withOpacity(0.08)
        : Colors.black.withOpacity(0.04);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.enableHover) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!widget.enableHover) return;
        setState(() => _hovered = false);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(baseShadowOpacity),
                  blurRadius: hovered ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
