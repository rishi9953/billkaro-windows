import 'package:billkaro/config/config.dart';

class PurchaseOrderHeaderBar extends StatelessWidget {
  const PurchaseOrderHeaderBar({
    super.key,
    required this.title,
    required this.onRefresh,
  });

  final String title;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      height: 56,
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: loc.refresh,
            onPressed: onRefresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
