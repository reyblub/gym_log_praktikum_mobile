/// Jalankan biasa untuk UTS praktikum (JSON lokal).
/// API tetap tersedia dengan --dart-define=USE_LOCAL_DATA=false.
class AppConfig {
  AppConfig._();

  static const useLocalData = bool.fromEnvironment(
    'USE_LOCAL_DATA',
    defaultValue: true,
  );

  static const favoriteStorageKey = useLocalData
      ? 'gym_log.practicum.local.favorites.v1'
      : 'gym_log.practicum.api.favorites.v1';
}
