import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/localization/strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import 'glass_widgets.dart';

class LanguageSelectorSheet extends ConsumerWidget {
  const LanguageSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const LanguageSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final code = ref.watch(localeProvider).languageCode;

    Widget option(String label, String c) {
      return ListRow(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            c.toUpperCase(),
            style: TextStyle(
              color: p.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: label,
        trailing: code == c
            ? Icon(CupertinoIcons.checkmark_alt, color: p.accent, size: 22)
            : null,
        onTap: () {
          ref.read(localeProvider.notifier).setLocale(Locale(c));
          Navigator.of(context).pop();
        },
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Text(context.s.language,
                  style: AppTheme.display(size: 28, color: p.text)),
            ),
            RowList(
              children: [
                option('English', 'en'),
                option('Bahasa Indonesia', 'id'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
