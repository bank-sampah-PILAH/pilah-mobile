import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

/// Registers the platform image picker so features can take it as a dependency
/// instead of constructing one.
///
/// [ImagePicker] is a thin handle over the platform channel and holds no state,
/// so a single shared instance is safe and there is nothing to dispose.
///
/// Registering it at all is what lets a cubit accept the picker through its
/// constructor: an `ImagePicker()` built inside a method can only be replaced
/// by swapping `ImagePickerPlatform.instance` out from under it, which reaches
/// past the class being tested to do it.
@module
abstract class ImagePickerModule {
  @lazySingleton
  ImagePicker get imagePicker => ImagePicker();
}
