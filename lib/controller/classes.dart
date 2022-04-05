class UpdateVersion {
  final String? version, description;

  UpdateVersion({
    required this.version,
    required this.description,
  });
}

enum LoadingStatus {
  loading,
  error,
  loaded,
}
