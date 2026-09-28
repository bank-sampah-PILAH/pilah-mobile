/// Turns whatever a media field came back as into something `Image.network`
/// can fetch, or null when there is nothing to show.
///
/// Which shape it is depends on the backend's storage: with a GCS bucket
/// configured the field serialises to a full https URL, while the local
/// FileSystemStorage yields a bare `/media/...` path that needs resolving
/// against the API origin. Shared so every feature that renders a backend
/// media field resolves it the same way.
///
/// [origin] is only invoked when the raw value is actually relative, so
/// callers may pass something that reaches out for configuration (or throws
/// on an unstubbed test double) without paying for it on every call.
String? resolveMediaUrl(String? raw, String Function() origin) {
  final url = raw?.trim();
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = origin();
  if (base.isEmpty) return url;
  return '${base.replaceAll(RegExp(r'/+$'), '')}'
      '/${url.replaceAll(RegExp(r'^/+'), '')}';
}
