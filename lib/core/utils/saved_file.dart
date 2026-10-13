/// A file that made it to disk: where it landed, and the folder name to say out
/// loud. [folder] is not always the directory's basename — the fallbacks below
/// live in paths no user would recognise, so they get a plain-language label.
class SavedFile {
  final String path;
  final String folder;

  const SavedFile({required this.path, required this.folder});
}
