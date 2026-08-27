import 'package:billkaro/app/modules/Wallet/wallet_controller.dart';
import 'package:billkaro/app/services/Modals/wallet/wallet_transaction.dart';
import 'package:billkaro/app/services/razorpay/razorpay_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

abstract final class _WalletStyle {
  static Color title(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  static const sectionLetterSpacing = 0.5;
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const double _maxWidth = 1120;

  bool _isWindows(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = Get.put(WalletController());
    final isWindows = _isWindows(context);
    final dateFmt = DateFormat('dd MMM, yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.wallet_title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => controller.loadWalletData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        elevation: isWindows ? 0 : null,
        scrolledUnderElevation: isWindows ? 0 : null,
        surfaceTintColor: isWindows ? Colors.transparent : null,
        toolbarHeight: isWindows ? 48 : kToolbarHeight,
        bottom: isWindows
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
              )
            : null,
      ),
      body: Obx(() {
        final loading = controller.isProcessingPayment.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: isWindows
                    ? Border(
                        top: BorderSide(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      )
                    : null,
              ),
              child: isWindows
                  ? _WindowsBody(
                      controller: controller,
                      loc: loc,
                      dateFmt: dateFmt,
                    )
                  : _MobileBody(
                      controller: controller,
                      loc: loc,
                      dateFmt: dateFmt,
                    ),
            ),
            if (loading) const Positioned.fill(child: _LoadingOverlay()),
          ],
        );
      }),
    );
  }
}

// ─── Windows ─────────────────────────────────────────────────────────────────

class _WindowsBody extends StatelessWidget {
  const _WindowsBody({
    required this.controller,
    required this.loc,
    required this.dateFmt,
  });

  final WalletController controller;
  final AppLocalizations loc;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: WalletScreen._maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchBar(controller: controller),
              const Gap(20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _BalanceCard(
                      controller: controller,
                      loc: loc,
                    ),
                  ),
                  const Gap(20),
                  Expanded(
                    flex: 2,
                    child: _InsightsCard(
                      controller: controller,
                      loc: loc,
                    ),
                  ),
                ],
              ),
              if (controller.isLowBalance) ...[
                const Gap(14),
                _LowBalanceBanner(loc: loc),
              ],
              const Gap(20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _QuickAddCard(
                      controller: controller,
                      loc: loc,
                    ),
                  ),
                  const Gap(20),
                  Expanded(
                    flex: 3,
                    child: _TransactionsCard(
                      controller: controller,
                      loc: loc,
                      dateFmt: dateFmt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: Colors.grey.shade500),
          const Gap(10),
          Expanded(
            child: TextField(
              onChanged: controller.setSearchQuery,
              style: TextStyle(fontSize: 14, color: _WalletStyle.title(context)),
              decoration: InputDecoration(
                hintText: 'Search transactions…',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.controller, required this.loc});

  final WalletController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Observe balance + transactions for reactive totals.
      final _ = controller.balance.value + controller.transactions.length;
      return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.primary,
            AppColor.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.wallet_balance.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 1,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      controller.outletLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: controller.isLowBalance ? 'Low' : 'Active',
                color: controller.isLowBalance
                    ? AppColor.warning
                    : AppColor.success,
              ),
            ],
          ),
          const Gap(18),
          Text(
            controller.formatAmount(controller.balance.value),
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const Gap(6),
          Text(
            loc.wallet_balance_subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const Gap(18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: 'Holder', value: controller.holderName),
              _MetaChip(
                label: 'Topped up',
                value: controller.formatAmount(controller.totalToppedUp),
              ),
            ],
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    final cards = controller.walletCards;
                    if (cards.isNotEmpty) {
                      controller.rechargeFromCard(cards.first);
                    } else {
                      controller.showCustomAmountDialog();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.secondaryPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: Text(
                    loc.wallet_add_money,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Gap(10),
              OutlinedButton(
                onPressed: controller.showCustomAmountDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.tune_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
    });
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.controller, required this.loc});

  final WalletController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LeadingIcon(Icons.insights_outlined),
              const Gap(10),
              Text(
                'Wallet Insights',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _WalletStyle.title(context),
                ),
              ),
            ],
          ),
          const Gap(18),
          SizedBox(
            height: 64,
            child: Obx(() => _WeeklyChart(bars: controller.weeklyCreditBars)),
          ),
          const Gap(14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColor.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Obx(
              () => Text(
                controller.aiInsightMessage(loc),
                style: TextStyle(
                  fontSize: 12.5,
                  color: _WalletStyle.muted(context),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.bars});

  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(bars.length, (i) {
        final highlight = i == bars.length - 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 64 * bars[i],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: highlight
                    ? AppColor.secondaryPrimary
                    : AppColor.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({required this.controller, required this.loc});

  final WalletController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(loc.wallet_add_money),
          const Gap(14),
          Obx(() {
            final cards = controller.walletCards;
            if (cards.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      loc.wallet_no_cards_available,
                      style: TextStyle(
                        fontSize: 13,
                        color: _WalletStyle.muted(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                  _AmountTile(
                    label: loc.wallet_custom_amount,
                    icon: Icons.add_rounded,
                    onTap: controller.showCustomAmountDialog,
                  ),
                ],
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.15,
              children: [
                ...cards.map(
                  (card) => _AmountTile(
                    label: card.title,
                    subtitle: card.bonusAmount > 0
                        ? '+${controller.formatAmount(card.bonusAmount)} bonus'
                        : controller.formatAmount(card.amount),
                    onTap: () => controller.rechargeFromCard(card),
                  ),
                ),
                _AmountTile(
                  label: loc.wallet_custom_amount,
                  icon: Icons.add_rounded,
                  onTap: controller.showCustomAmountDialog,
                ),
              ],
            );
          }),
          const Gap(14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 15, color: Colors.grey.shade500),
              const Gap(8),
              Expanded(
                child: Text(
                  RazorpayService.isTestMode
                      ? 'Test mode: select UPI and enter ${RazorpayService.testUpiId}'
                      : loc.wallet_secure_payment_note,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountTile extends StatefulWidget {
  const _AmountTile({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_AmountTile> createState() => _AmountTileState();
}

class _AmountTileState extends State<_AmountTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: _hover
            ? AppColor.primary.withValues(alpha: 0.04)
            : AppColor.backGroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hover
                    ? AppColor.primary.withValues(alpha: 0.35)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: AppColor.primary),
                  const Gap(4),
                ],
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _hover ? AppColor.primary : _WalletStyle.title(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.subtitle != null) ...[
                        const Gap(2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({
    required this.controller,
    required this.loc,
    required this.dateFmt,
  });

  final WalletController controller;
  final AppLocalizations loc;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.filteredTransactions;
      return _SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Text(
                    loc.wallet_history,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _WalletStyle.title(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${list.length} ${loc.wallet_transactions}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _WalletStyle.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: _EmptyState(loc: loc),
              )
            else ...[
              const _TableHeader(),
              ...list.map(
                (tx) => _TableRow(
                  tx: tx,
                  controller: controller,
                  dateFmt: dateFmt,
                ),
              ),
              const Gap(6),
            ],
          ],
        ),
      );
    });
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: _TH('DESCRIPTION')),
          Expanded(flex: 2, child: _TH('TYPE')),
          Expanded(flex: 3, child: _TH('DATE')),
          Expanded(
            flex: 2,
            child: _TH('AMOUNT', align: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.text, {this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: _WalletStyle.sectionLetterSpacing,
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.tx,
    required this.controller,
    required this.dateFmt,
  });

  final WalletTransaction tx;
  final WalletController controller;
  final DateFormat dateFmt;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final credit = widget.tx.isCredit;
    final color = credit ? AppColor.success : AppColor.error;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? AppColor.backGroundColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _TxIcon(credit: credit),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      widget.tx.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _WalletStyle.title(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                credit ? 'Credit' : 'Debit',
                style: TextStyle(
                  fontSize: 12,
                  color: _WalletStyle.muted(context),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.dateFmt.format(widget.tx.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: _WalletStyle.muted(context),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${credit ? '+' : '-'}${widget.controller.formatAmount(widget.tx.amount)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowBalanceBanner extends StatelessWidget {
  const _LowBalanceBanner({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20),
          const Gap(10),
          Expanded(
            child: Text(
              loc.wallet_low_balance_warning,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFFB91C1C),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile ──────────────────────────────────────────────────────────────────

class _MobileBody extends StatelessWidget {
  const _MobileBody({
    required this.controller,
    required this.loc,
    required this.dateFmt,
  });

  final WalletController controller;
  final AppLocalizations loc;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final activityFmt = DateFormat('dd MMM, yyyy · hh:mm a');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCard(controller: controller, loc: loc),
          if (controller.isLowBalance) ...[
            const Gap(12),
            _LowBalanceBanner(loc: loc),
          ],
          const Gap(16),
          _QuickAddCard(controller: controller, loc: loc),
          const Gap(16),
          _InsightsCard(controller: controller, loc: loc),
          const Gap(16),
          Obx(() {
            final list = controller.filteredTransactions;
            return _SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          loc.wallet_history,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _WalletStyle.title(context),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${list.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _WalletStyle.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyState(loc: loc),
                    )
                  else
                    ...list.map(
                      (tx) => _ActivityRow(
                        tx: tx,
                        controller: controller,
                        dateFmt: activityFmt,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.tx,
    required this.controller,
    required this.dateFmt,
  });

  final WalletTransaction tx;
  final WalletController controller;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final color = credit ? AppColor.success : AppColor.error;

    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _TxIcon(credit: credit),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _WalletStyle.title(context),
                    ),
                  ),
                  const Gap(2),
                  Text(
                    dateFmt.format(tx.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: _WalletStyle.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${credit ? '+' : '-'}${controller.formatAmount(tx.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared ──────────────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.35);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _WalletStyle.muted(context),
        letterSpacing: _WalletStyle.sectionLetterSpacing,
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColor.primary, size: 20),
    );
  }
}

class _TxIcon extends StatelessWidget {
  const _TxIcon({required this.credit});

  final bool credit;

  @override
  Widget build(BuildContext context) {
    final color = credit ? AppColor.success : AppColor.error;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        credit ? Icons.add_rounded : Icons.remove_rounded,
        color: color,
        size: 18,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade400),
        const Gap(10),
        Text(
          loc.wallet_no_transactions,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _WalletStyle.muted(context),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.25),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const Gap(14),
              Text(
                'Opening secure checkout…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _WalletStyle.title(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
