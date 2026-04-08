import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a [ProfileApiService] backed by the authenticated Dio client.
final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.watch(httpClientProvider));
});

/// Profile controller — fetches and manages the current user's profile.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, DisplayableProfile>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<DisplayableProfile> {
  @override
  Future<DisplayableProfile> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      throw StateError('No authenticated user');
    }

    final service = ref.watch(profileApiServiceProvider);

    try {
      if (user.userType == UserType.farmer) {
        final json = await service.getFarmerProfile(user.uid);
        final profile = FarmerProfileModel.fromJson(json);
        return CompleteFarmerProfile.fromModels(user: user, profile: profile);
      } else {
        final json = await service.getMerchantProfile(user.uid);
        final profile = MerchantProfileModel.fromJson(json);
        return CompleteMerchantProfile.fromModels(user: user, profile: profile);
      }
    } on DioException catch (e) {
      // 404 means profile not yet created — return minimal
      if (e.response?.statusCode == 404) {
        return MinimalProfile.fromUserModel(user);
      }
      rethrow;
    }
  }

  /// Updates the farmer profile. Returns null on success, error message on failure.
  Future<String?> updateFarmerProfile(
    String profileId,
    FarmerProfileModel updated,
  ) async {
    try {
      final service = ref.read(profileApiServiceProvider);
      await service.updateFarmerProfile(profileId, updated.toUpdateRequest());
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_update_failed';
    }
  }

  /// Updates the merchant profile. Returns null on success, error message on failure.
  Future<String?> updateMerchantProfile(
    String profileId,
    MerchantProfileModel updated,
  ) async {
    try {
      final service = ref.read(profileApiServiceProvider);
      await service.updateMerchantProfile(
        profileId,
        updated.toUpdateRequest(),
      );
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_update_failed';
    }
  }

  /// Creates a farmer profile. Returns null on success, error message on failure.
  Future<String?> createFarmerProfile(FarmerProfileModel profile) async {
    try {
      final service = ref.read(profileApiServiceProvider);
      await service.createFarmerProfile(profile.toCreateRequest());
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_save_failed';
    }
  }

  /// Creates a merchant profile. Returns null on success, error message on failure.
  Future<String?> createMerchantProfile(MerchantProfileModel profile) async {
    try {
      final service = ref.read(profileApiServiceProvider);
      await service.createMerchantProfile(profile.toCreateRequest());
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return 'error_save_failed';
    }
  }

  /// Deletes the profile from the backend. Returns null on success, error message on failure.
  Future<String?> deleteProfile(String profileId) async {
    try {
      final service = ref.read(profileApiServiceProvider);
      await service.deleteProfile(profileId);
      return null;
    } catch (e) {
      return 'error_delete_failed';
    }
  }
}
