import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

/// Registers the platform image picker and cropper so features can take them as
/// dependencies instead of constructing them.
///
/// Both are thin handles over platform channels and hold no state, so a single
/// shared instance of each is safe and there is nothing to dispose.
///
/// Registering them at all is what lets a cubit accept them through its
/// constructor: an `ImagePicker()` built inside a method can only be replaced
/// by swapping `ImagePickerPlatform.instance` out from under it, which reaches
/// past the class being tested to do it.
@module
abstract class ImagePickerModule {
  @lazySingleton
  ImagePicker get imagePicker => ImagePicker();

  @lazySingleton
  ImageCropper get imageCropper => ImageCropper();
}
