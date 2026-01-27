// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the current settings

@ProviderFor(SettingsNotifier)
final settingsProvider = SettingsNotifierProvider._();

/// Provider for the current settings
final class SettingsNotifierProvider
    extends $NotifierProvider<SettingsNotifier, SettingsModel> {
  /// Provider for the current settings
  SettingsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsNotifierHash();

  @$internal
  @override
  SettingsNotifier create() => SettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsModel>(value),
    );
  }
}

String _$settingsNotifierHash() => r'9a543325e62416d959715b45924dbcb34a5f7072';

/// Provider for the current settings

abstract class _$SettingsNotifier extends $Notifier<SettingsModel> {
  SettingsModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SettingsModel, SettingsModel>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SettingsModel, SettingsModel>,
        SettingsModel,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
