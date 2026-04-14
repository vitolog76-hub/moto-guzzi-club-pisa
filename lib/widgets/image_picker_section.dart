import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerSection extends StatelessWidget {
  static const int maxImages = 5;
  static const Color _guzziRed = Color(0xFF8B0000);

  final List<String> existingImageUrls;
  final List<XFile> newImages;
  final ValueChanged<List<XFile>> onNewImagesPicked;
  final ValueChanged<int> onExistingImageRemoved;
  final ValueChanged<int> onNewImageRemoved;

  const ImagePickerSection({
    super.key,
    required this.existingImageUrls,
    required this.newImages,
    required this.onNewImagesPicked,
    required this.onExistingImageRemoved,
    required this.onNewImageRemoved,
  });

  int get _totalCount => existingImageUrls.length + newImages.length;
  bool get _canAddMore => _totalCount < maxImages;

  Future<void> _pickImages() async {
    final remaining = maxImages - _totalCount;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final toAdd = picked.length > remaining ? picked.sublist(0, remaining) : picked;
    onNewImagesPicked(toAdd);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Locandine (max $maxImages)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _totalCount + (_canAddMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < existingImageUrls.length) {
              return _buildExistingTile(index);
            }
            final newIndex = index - existingImageUrls.length;
            if (newIndex < newImages.length) {
              return _buildNewTile(newIndex);
            }
            return _buildAddTile();
          },
        ),
      ],
    );
  }

  Widget _buildExistingTile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            existingImageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _buildRemoveButton(() => onExistingImageRemoved(index)),
        ),
      ],
    );
  }

  Widget _buildNewTile(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            newImages[index].path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _buildRemoveButton(() => onNewImageRemoved(index)),
        ),
      ],
    );
  }

  Widget _buildRemoveButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _guzziRed, style: BorderStyle.solid, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: _guzziRed.withOpacity(0.05),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: _guzziRed, size: 32),
            SizedBox(height: 4),
            Text(
              'Aggiungi',
              style: TextStyle(color: _guzziRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
