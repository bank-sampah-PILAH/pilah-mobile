/// Result of saving to native storage or starting a browser-managed download.
class SavedFile {
  const SavedFile({required this.path, required this.folder})
      : isBrowserDownload = false;

  const SavedFile.browser()
      : path = '',
        folder = 'Unduhan browser',
        isBrowserDownload = true;

  /// Native filesystem path. Browser downloads have no app-accessible path.
  final String path;
  final String folder;
  final bool isBrowserDownload;
}
