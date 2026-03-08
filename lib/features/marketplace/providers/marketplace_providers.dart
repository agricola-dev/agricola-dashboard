import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [MarketplaceApiService] backed by the authenticated Dio client.
final marketplaceApiServiceProvider = Provider<MarketplaceApiService>((ref) {
  return MarketplaceApiService(ref.watch(httpClientProvider));
});

// ---------------------------------------------------------------------------
// My Listings
// ---------------------------------------------------------------------------

/// Sort fields for the My Listings table.
enum ListingSortField {
  title,
  price,
  createdAt,
}

/// Sort configuration: field + direction.
class ListingSort {
  const ListingSort({
    this.field = ListingSortField.createdAt,
    this.ascending = false,
  });

  final ListingSortField field;
  final bool ascending;

  ListingSort copyWith({ListingSortField? field, bool? ascending}) {
    return ListingSort(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Search text for filtering the user's listings.
final myListingsSearchProvider = StateProvider<String>((_) => '');

/// Current sort configuration for the user's listings.
final myListingsSortProvider = StateProvider<ListingSort>(
  (_) => const ListingSort(),
);

/// Controller for the current user's marketplace listings — owns CRUD.
final myListingsControllerProvider =
    AsyncNotifierProvider<MyListingsController, List<MarketplaceListing>>(
  MyListingsController.new,
);

class MyListingsController extends AsyncNotifier<List<MarketplaceListing>> {
  @override
  Future<List<MarketplaceListing>> build() async {
    final service = ref.watch(marketplaceApiServiceProvider);
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return service.getListings(
      filter: MarketplaceFilter(sellerId: user.uid),
    );
  }

  /// Creates a new listing. Returns null on success, error message on failure.
  Future<String?> createListing(MarketplaceListing listing) async {
    try {
      final service = ref.read(marketplaceApiServiceProvider);
      await service.createListing(listing);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Updates an existing listing. Returns null on success, error message on failure.
  Future<String?> updateListing(String id, MarketplaceListing listing) async {
    try {
      final service = ref.read(marketplaceApiServiceProvider);
      await service.updateListing(id, listing);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes a listing. Returns null on success, error message on failure.
  Future<String?> deleteListing(String id) async {
    try {
      final service = ref.read(marketplaceApiServiceProvider);
      await service.deleteListing(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Derived provider that filters by search text and sorts the user's listings.
final filteredMyListingsProvider =
    Provider<AsyncValue<List<MarketplaceListing>>>((ref) {
  final asyncItems = ref.watch(myListingsControllerProvider);
  final search = ref.watch(myListingsSearchProvider).toLowerCase();
  final sort = ref.watch(myListingsSortProvider);

  return asyncItems.whenData((items) {
    // Filter
    var filtered = items;
    if (search.isNotEmpty) {
      filtered = items.where((item) {
        return item.title.toLowerCase().contains(search) ||
            item.category.toLowerCase().contains(search) ||
            item.location.toLowerCase().contains(search) ||
            item.description.toLowerCase().contains(search);
      }).toList();
    }

    // Sort
    filtered = List.of(filtered);
    filtered.sort((a, b) {
      int result;
      switch (sort.field) {
        case ListingSortField.title:
          result = a.title.compareTo(b.title);
        case ListingSortField.price:
          result = (a.price ?? 0).compareTo(b.price ?? 0);
        case ListingSortField.createdAt:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return sort.ascending ? result : -result;
    });

    return filtered;
  });
});

// ---------------------------------------------------------------------------
// Browse Marketplace
// ---------------------------------------------------------------------------

/// Filter state for browsing all marketplace listings.
final browseFilterProvider = StateProvider<MarketplaceFilter>(
  (_) => const MarketplaceFilter(),
);

/// Controller for browsing all marketplace listings.
final browseListingsControllerProvider =
    AsyncNotifierProvider<BrowseListingsController, List<MarketplaceListing>>(
  BrowseListingsController.new,
);

class BrowseListingsController
    extends AsyncNotifier<List<MarketplaceListing>> {
  @override
  Future<List<MarketplaceListing>> build() async {
    final service = ref.watch(marketplaceApiServiceProvider);
    final filter = ref.watch(browseFilterProvider);
    return service.getListings(filter: filter);
  }
}
