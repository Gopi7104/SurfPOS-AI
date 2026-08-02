import 'package:flutter/material.dart';

import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_typography.dart';

/// One searchable Settings entry — either a [sectionTitle] (the caller
/// scrolls the already-open Settings Home to that section's `GlobalKey`)
/// or a [pageBuilder] for settings that already live on their own real
/// page (Merchant Profile, Payment, Printer, Developer Tools, About, ...),
/// which navigates there directly. Never both — a result always maps to
/// something real, never a dead end.
class SettingsSearchEntry {
  const SettingsSearchEntry(
      {required this.label, this.sectionTitle, this.pageBuilder})
      : assert(sectionTitle != null || pageBuilder != null);

  final String label;
  final String? sectionTitle;
  final WidgetBuilder? pageBuilder;
}

/// Settings Search — `showSearch()`'s standard delegate, filtering
/// [entries] by [SettingsSearchEntry.label] with instant results as you
/// type. Tapping a result either pushes the real page it belongs to, or
/// closes the search and asks [onSectionSelected] to scroll Settings Home
/// to that section.
class SettingsSearchDelegate extends SearchDelegate<void> {
  SettingsSearchDelegate(
      {required this.entries, required this.onSectionSelected});

  final List<SettingsSearchEntry> entries;
  final ValueChanged<String> onSectionSelected;

  @override
  String get searchFieldLabel => 'Search settings';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  List<SettingsSearchEntry> _matches() {
    if (query.trim().isEmpty) return entries;
    final q = query.toLowerCase();
    return entries.where((e) => e.label.toLowerCase().contains(q)).toList();
  }

  void _select(BuildContext context, SettingsSearchEntry entry) {
    if (entry.pageBuilder != null) {
      close(context, null);
      Navigator.of(context)
          .push(MaterialPageRoute(builder: entry.pageBuilder!));
    } else {
      close(context, null);
      onSectionSelected(entry.sectionTitle!);
    }
  }

  Widget _buildList(BuildContext context) {
    final results = _matches();
    if (results.isEmpty) {
      return Center(
        child: Text('No settings match "$query"',
            style: AppTypography.bodyMD.copyWith(color: AppColors.textGrey)),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final entry = results[index];
        return ListTile(
          title: Text(entry.label, style: AppTypography.bodyMD),
          subtitle: entry.sectionTitle == null
              ? null
              : Text(entry.sectionTitle!, style: AppTypography.caption),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
          onTap: () => _select(context, entry),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);
}
