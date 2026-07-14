import 'package:billkaro/app/modules/Language/language_controller.dart';
import 'package:billkaro/config/config.dart';

Future<void> showLanguagePickerDialog(BuildContext context) {
  final controller = Get.find<LanguageController>();
  final loc = AppLocalizations.of(context)!;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.select_language_title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      tooltip: loc.close,
                      icon: Icon(Icons.close, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  loc.select_preferred_language_for_app,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Lottie.asset(
                    'assets/lottie/translatelanguage.json',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  return Column(
                    children: [
                      for (var index = 0;
                          index < controller.languages.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == controller.languages.length - 1
                                ? 0
                                : 10,
                          ),
                          child: _LanguageOptionTile(
                            code: index == 0 ? 'EN' : 'HI',
                            title: index == 0 ? 'English' : 'हिन्दी',
                            subtitle: index == 0 ? 'English (US)' : 'हिन्दी',
                            selected:
                                controller.languages[index] ==
                                controller.selectedLanguage.value,
                            onTap: () async {
                              await controller.changeLanguage(
                                Locale(index == 0 ? 'en' : 'hi'),
                              );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColor.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withOpacity(0.12)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected ? accent : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accent : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
