import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../services/local_image_service.dart';
import '../utils/messages.dart';
import 'app_button.dart';
import 'brand_mark.dart';
import 'screen_shell.dart';

class LocalImageEditor extends StatefulWidget {
  const LocalImageEditor({
    required this.uid,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.firebasePath,
    required this.onSave,
    required this.previewIcon,
    this.squarePreview = false,
    super.key,
  });

  final String uid;
  final String title;
  final String subtitle;
  final LocalImageKind kind;
  final String firebasePath;
  final Future<void> Function(String path) onSave;
  final IconData previewIcon;
  final bool squarePreview;

  @override
  State<LocalImageEditor> createState() => _LocalImageEditorState();
}

class _LocalImageEditorState extends State<LocalImageEditor> {
  final _imageService = LocalImageService();

  String _selectedPath = '';
  bool _pickedInSession = false;
  bool _isPicking = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialPath();
  }

  @override
  void didUpdateWidget(covariant LocalImageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pickedInSession && oldWidget.firebasePath != widget.firebasePath) {
      _resolveInitialPath();
    }
  }

  Future<void> _resolveInitialPath() async {
    final resolved = await _imageService.resolveAvailablePath(
      uid: widget.uid,
      kind: widget.kind,
      firebasePath: widget.firebasePath,
    );
    if (mounted && !_pickedInSession) {
      setState(() => _selectedPath = resolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: widget.title,
                subtitle: widget.subtitle,
                showBack: true,
              ),
              const SizedBox(height: 30),
              Center(
                child: _ImagePreview(
                  path: _selectedPath,
                  icon: widget.previewIcon,
                  square: widget.squarePreview,
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Zgjidh nga galeria',
                icon: Icons.photo_library_outlined,
                isLoading: _isPicking,
                onPressed: _pickImage,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.phone_android_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Imazhi ruhet vetëm në këtë pajisje. Në Firebase '
                        'ruhet vetëm rruga lokale e skedarit.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Ruaj',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _selectedPath.isEmpty ? null : _save,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Kthehu',
                style: AppButtonStyle.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    try {
      final path = await _imageService.pickAndPersist(
        uid: widget.uid,
        kind: widget.kind,
      );
      if (mounted && path != null) {
        setState(() {
          _selectedPath = path;
          _pickedInSession = true;
        });
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(
          context,
          'Fotografia nuk mund të zgjidhej.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_selectedPath);
      if (mounted) {
        showAppMessage(context, 'Imazhi u ruajt në pajisje.');
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Imazhi nuk u ruajt.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.path,
    required this.icon,
    required this.square,
  });

  final String path;
  final IconData icon;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final hasImage = path.isNotEmpty && File(path).existsSync();
    final width = square ? 168.0 : 184.0;
    final height = square ? 168.0 : 220.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(square ? 34 : 28),
        border: Border.all(color: AppColors.outline, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _PreviewFallback(icon: icon),
            )
          : _PreviewFallback(icon: icon),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: AppColors.primary, size: 70));
  }
}
