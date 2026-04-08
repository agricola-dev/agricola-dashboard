import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/providers/pagination_provider.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/core/widgets/table_pagination_bar.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/marketplace/presentation/marketplace_form_dialog.dart';
import 'package:agricola_dashboard/features/marketplace/presentation/widgets/listing_type_badge.dart';
import 'package:agricola_dashboard/features/marketplace/presentation/widgets/price_display.dart';
import 'package:agricola_dashboard/features/marketplace/providers/marketplace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header with tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Text(
                t('marketplace', lang),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(text: t('my_listings', lang)),
                    Tab(text: t('browse_marketplace', lang)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MyListingsTab(lang: lang),
              _BrowseMarketplaceTab(lang: lang),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// My Listings tab
// ---------------------------------------------------------------------------

class _MyListingsTab extends ConsumerWidget {
  const _MyListingsTab({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredMyListingsProvider);
    final sort = ref.watch(myListingsSortProvider);

    return filteredAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: t('error_try_again', lang),
        onRetry: () => ref.invalidate(myListingsControllerProvider),
        lang: lang,
      ),
      data: (items) => _MyListingsContent(
        items: items,
        sort: sort,
        lang: lang,
      ),
    );
  }
}

class _MyListingsContent extends ConsumerWidget {
  const _MyListingsContent({
    required this.items,
    required this.sort,
    required this.lang,
  });

  final List<MarketplaceListing> items;
  final ListingSort sort;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagination = ref.watch(paginationProvider('my_listings'));
    final pageItems = paginateList(items, pagination);

    ref.listen(myListingsSearchProvider, (_, __) {
      ref.read(paginationProvider('my_listings').notifier).state =
          ref.read(paginationProvider('my_listings')).copyWith(currentPage: 0);
    });
    ref.listen(myListingsSortProvider, (_, __) {
      ref.read(paginationProvider('my_listings').notifier).state =
          ref.read(paginationProvider('my_listings')).copyWith(currentPage: 0);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubHeader(context, ref),
          const SizedBox(height: 24),
          if (items.isEmpty)
            _EmptyState(lang: lang, onAdd: () => _addListing(context, ref))
          else ...[
            _buildTable(context, ref, pageItems),
            const SizedBox(height: 16),
            TablePaginationBar(
              totalItems: items.length,
              pagination: pagination,
              onPageChanged: (page) =>
                  ref.read(paginationProvider('my_listings').notifier).state =
                      pagination.copyWith(currentPage: page),
              onRowsPerPageChanged: (rows) =>
                  ref.read(paginationProvider('my_listings').notifier).state =
                      const PaginationState().copyWith(rowsPerPage: rows),
              lang: lang,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Count chip
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text('${items.length}'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        // Search + Add button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              child: AppTextField(
                label: t('search', lang),
                prefixIcon: Icons.search,
                onChanged: (value) =>
                    ref.read(myListingsSearchProvider.notifier).state = value,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _addListing(context, ref),
              icon: const Icon(Icons.add),
              label: Text(t('add_listing', lang)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, List<MarketplaceListing> pageItems) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        sortColumnIndex: sort.field.index,
        sortAscending: sort.ascending,
        headingRowColor: WidgetStateProperty.all(
          colors.surfaceContainerLow,
        ),
        columns: [
          DataColumn(
            label: Text(t('listing_title', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, ListingSortField.title, ascending),
          ),
          DataColumn(label: Text(t('listing_type', lang))),
          DataColumn(label: Text(t('listing_category', lang))),
          DataColumn(
            label: Text(t('listing_price', lang)),
            numeric: true,
            onSort: (_, ascending) =>
                _onSort(ref, ListingSortField.price, ascending),
          ),
          DataColumn(label: Text(t('listing_quantity', lang))),
          DataColumn(label: Text(t('listing_location', lang))),
          DataColumn(
            label: Text(t('created_date', lang)),
            onSort: (_, ascending) =>
                _onSort(ref, ListingSortField.createdAt, ascending),
          ),
          DataColumn(label: Text(t('actions', lang))),
        ],
        rows: pageItems
            .map((item) => _buildRow(context, ref, item, colors))
            .toList(),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    MarketplaceListing item,
    ColorScheme colors,
  ) {
    final created =
        '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}';

    return DataRow(
      cells: [
        DataCell(Text(item.title)),
        DataCell(ListingTypeBadge(type: item.type, lang: lang)),
        DataCell(Text(item.category)),
        DataCell(PriceDisplay(price: item.price, unit: item.unit, lang: lang)),
        DataCell(Text(item.quantity ?? '—')),
        DataCell(Text(item.location)),
        DataCell(Text(created)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: t('edit_listing', lang),
                onPressed: () => _editListing(context, ref, item),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
                tooltip: t('delete_listing', lang),
                onPressed: () => _deleteListing(context, ref, item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSort(WidgetRef ref, ListingSortField field, bool ascending) {
    ref.read(myListingsSortProvider.notifier).state = ListingSort(
      field: field,
      ascending: ascending,
    );
  }

  Future<void> _addListing(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await showMarketplaceFormDialog(
      context,
      lang: lang,
      sellerId: user.uid,
      sellerName: user.email,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(myListingsControllerProvider.notifier)
        .createListing(result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'listing_created',
    );
  }

  Future<void> _editListing(
    BuildContext context,
    WidgetRef ref,
    MarketplaceListing item,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await showMarketplaceFormDialog(
      context,
      lang: lang,
      sellerId: user.uid,
      sellerName: user.email,
      listing: item,
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(myListingsControllerProvider.notifier)
        .updateListing(item.id, result);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'listing_updated',
    );
  }

  Future<void> _deleteListing(
    BuildContext context,
    WidgetRef ref,
    MarketplaceListing item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_listing', lang)),
        content: Text(t('delete_listing_confirm', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('cancel', lang)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('delete', lang)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(myListingsControllerProvider.notifier)
        .deleteListing(item.id);

    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successKey: 'listing_deleted',
    );
  }

  void _showResultSnackBar(
    BuildContext context, {
    required String? error,
    required String successKey,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t(error, lang)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(t(successKey, lang))),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Browse Marketplace tab
// ---------------------------------------------------------------------------

class _BrowseMarketplaceTab extends ConsumerWidget {
  const _BrowseMarketplaceTab({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncListings = ref.watch(browseListingsControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrowseFilterBar(lang: lang),
          const SizedBox(height: 24),
          asyncListings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorView(
              message: t('error_try_again', lang),
              onRetry: () =>
                  ref.invalidate(browseListingsControllerProvider),
              lang: lang,
            ),
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t('marketplace_empty', lang),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _BrowseGrid(items: items, lang: lang),
          ),
        ],
      ),
    );
  }
}

class _BrowseFilterBar extends ConsumerWidget {
  const _BrowseFilterBar({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(browseFilterProvider);
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Search
        SizedBox(
          width: 260,
          child: AppTextField(
            label: t('search', lang),
            prefixIcon: Icons.search,
            onChanged: (value) {
              ref.read(browseFilterProvider.notifier).state =
                  filter.copyWith(searchQuery: value);
            },
          ),
        ),
        // Type filter
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<ListingType?>(
            initialValue: filter.itemType,
            decoration: InputDecoration(
              labelText: t('filter_by_type', lang),
              prefixIcon: const Icon(Icons.filter_list),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(t('all_types', lang)),
              ),
              ...ListingType.values.map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(t(type.name, lang)),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(browseFilterProvider.notifier).state =
                  MarketplaceFilter(
                searchQuery: filter.searchQuery,
                itemType: value,
                category: filter.category,
                minPrice: filter.minPrice,
                maxPrice: filter.maxPrice,
              );
            },
          ),
        ),
        // Clear filters
        if (filter.hasActiveFilters)
          TextButton.icon(
            onPressed: () {
              ref.read(browseFilterProvider.notifier).state =
                  const MarketplaceFilter();
            },
            icon: const Icon(Icons.clear),
            label: Text(t('clear_filters', lang)),
            style: TextButton.styleFrom(foregroundColor: colors.error),
          ),
      ],
    );
  }
}

class _BrowseGrid extends StatelessWidget {
  const _BrowseGrid({required this.items, required this.lang});

  final List<MarketplaceListing> items;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _ListingCard(listing: items[index], lang: lang),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.lang});

  final MarketplaceListing listing;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + type badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ListingTypeBadge(type: listing.type, lang: lang),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Expanded(
              child: Text(
                listing.description,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Price
            PriceDisplay(
              price: listing.price,
              unit: listing.unit,
              lang: lang,
            ),
            const SizedBox(height: 4),
            // Location + seller
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: colors.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    listing.location,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.person, size: 14, color: colors.outline),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    listing.sellerName,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.lang, required this.onAdd});

  final AppLanguage lang;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              t('no_listings', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('no_listings_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(t('add_listing', lang)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view with retry
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.lang,
  });

  final String message;
  final VoidCallback onRetry;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            t('error_loading_listings', lang),
            style: TextStyle(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t('retry', lang)),
          ),
        ],
      ),
    );
  }
}
