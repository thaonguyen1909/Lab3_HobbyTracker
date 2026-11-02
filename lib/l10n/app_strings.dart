import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'messages.dart';

class AppStrings {
  const AppStrings(this.languageCode);
  final String languageCode;
  static const supportedLocales = [Locale('en'), Locale('vi')];
  static const delegate = _AppStringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings('en');
  String text(String source) {
    final exact = localizedMessages[source];
    if (exact != null) return exact[languageCode == 'vi' ? 1 : 0];
    for (final entry in _patterns) {
      final match = entry.regex.firstMatch(source);
      if (match == null) continue;
      final output = entry.translations[languageCode == 'vi' ? 1 : 0];
      return output.replaceAllMapped(RegExp(r'\{(\d+)\}'), (placeholder) {
        final index = int.parse(placeholder.group(1)!) + 1;
        return index <= match.groupCount
            ? match.group(index) ?? ''
            : placeholder.group(0)!;
      });
    }
    return source;
  }

  static final _patterns =
      localizedMessages.entries
          .where((e) => e.key.contains(RegExp(r'\{\d+\}')))
          .map((e) {
            final parts = e.key.split(RegExp(r'\{\d+\}'));
            return _Pattern(
              RegExp(
                '^${parts.map(RegExp.escape).join('(.*?)')}\u0024',
                dotAll: true,
              ),
              e.value,
            );
          })
          .toList()
        ..sort(
          (a, b) => b.regex.pattern.length.compareTo(a.regex.pattern.length),
        );
}

class _Pattern {
  const _Pattern(this.regex, this.translations);
  final RegExp regex;
  final List<String> translations;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'vi'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.languageCode));
  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension TranslateContext on BuildContext {
  String tr(String source) => AppStrings.of(this).text(source);
}

/// Only app-owned copy uses this widget; user-authored text stays ordinary Text.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null ? null : context.tr(semanticsLabel!),
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}
