import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/editor_models.dart';

class EditorState {
  final String categoryId;
  final List<int> selectedOptions;
  final List<PhotoEdit> photos;
  final String? activePhotoId;
  final String? activeTextId;

  EditorState({
    required this.categoryId,
    required this.selectedOptions,
    required this.photos,
    this.activePhotoId,
    this.activeTextId,
  });

  EditorState copyWith({
    String? categoryId,
    List<int>? selectedOptions,
    List<PhotoEdit>? photos,
    String? activePhotoId,
    String? activeTextId,
    bool clearActivePhoto = false,
    bool clearActiveText = false,
  }) {
    return EditorState(
      categoryId: categoryId ?? this.categoryId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      photos: photos ?? this.photos,
      activePhotoId: clearActivePhoto ? null : (activePhotoId ?? this.activePhotoId),
      activeTextId: clearActiveText ? null : (activeTextId ?? this.activeTextId),
    );
  }
}

class EditorNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => EditorState(categoryId: '', selectedOptions: [], photos: []);

  void reset() {
    state = EditorState(categoryId: '', selectedOptions: [], photos: []);
  }

  void setProductContext(String categoryId, List<int> selectedOptions) {
    state = state.copyWith(categoryId: categoryId, selectedOptions: selectedOptions);
  }

  void addPhotos(List<String> paths) {
    final newPhotos = paths.asMap().entries.map((entry) {
      return PhotoEdit.initial(
        "${DateTime.now().millisecondsSinceEpoch}_${entry.key}",
        entry.value,
      );
    }).toList();
    state = state.copyWith(
      photos: [...state.photos, ...newPhotos],
      activePhotoId: newPhotos.isNotEmpty ? newPhotos.first.id : state.activePhotoId,
    );
  }

  void setActivePhoto(String? id) {
    state = state.copyWith(activePhotoId: id, clearActivePhoto: id == null);
  }

  void updatePhoto(String id, PhotoEdit Function(PhotoEdit) updater) {
    state = state.copyWith(
      photos: state.photos.map((p) => p.id == id ? updater(p) : p).toList(),
    );
  }

  void removePhoto(String id) {
    final newPhotos = state.photos.where((p) => p.id != id).toList();
    state = state.copyWith(
      photos: newPhotos,
      activePhotoId: state.activePhotoId == id 
          ? (newPhotos.isNotEmpty ? newPhotos.first.id : null) 
          : state.activePhotoId,
      clearActivePhoto: state.activePhotoId == id && newPhotos.isEmpty,
    );
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(() {
  return EditorNotifier();
});
