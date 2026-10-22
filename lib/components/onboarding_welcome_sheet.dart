import 'package:flutter/material.dart';
import '../services/folder_sync_service.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import 'app_logo.dart';

/// Modal wizard shown on first launch to configure reader profile name
/// and choose local library storage location.
class OnboardingWelcomeSheet extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingWelcomeSheet({
    super.key,
    this.onCompleted,
  });

  @override
  State<OnboardingWelcomeSheet> createState() => _OnboardingWelcomeSheetState();
}

class _OnboardingWelcomeSheetState extends State<OnboardingWelcomeSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController(text: 'Reader');
  int _currentStep = 0;
  String? _selectedFolderPath;
  bool _isScanning = false;
  int _discoveredBooksCount = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = 'Reader';
    }
    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickFolder() async {
    final path = await FolderSyncService.instance.pickAndLinkFolder();
    if (!mounted) return;
    if (path.isNotEmpty) {
      setState(() {
        _discoveredBooksCount = path.length;
      });
    }
    final linked = await StorageService.instance.getLinkedFolders();
    if (mounted && linked.isNotEmpty) {
      setState(() {
        _selectedFolderPath = linked.last;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isScanning = true);
    final finalName = _nameController.text.trim().isEmpty
        ? 'Reader'
        : _nameController.text.trim();

    await StorageService.instance.setUserName(finalName);
    if (_selectedFolderPath != null && _selectedFolderPath!.isNotEmpty) {
      await StorageService.instance.setDownloadsDirectoryPath(_selectedFolderPath!);
      await StorageService.instance.addLinkedFolder(_selectedFolderPath!);
      await FolderSyncService.instance.scanLinkedFolder(_selectedFolderPath!);
    }
    await StorageService.instance.setFirstLaunchDone(true);

    if (mounted) {
      setState(() => _isScanning = false);
      widget.onCompleted?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FoliateThemeColors>() ?? FoliateThemeColors.dark;
    final primaryAccent = theme.colorScheme.primary;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SizedBox(
            height: 480,
            child: Column(
              children: [
                // Top step pill indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIndicator(0, 'Welcome', primaryAccent, colors),
                    Container(
                      width: 32,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: _currentStep >= 1 ? primaryAccent : colors.border,
                    ),
                    _buildStepIndicator(1, 'Storage', primaryAccent, colors),
                  ],
                ),
                const SizedBox(height: 20),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepOne(colors, primaryAccent),
                      _buildStepTwo(colors, primaryAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
    int step,
    String label,
    Color accent,
    FoliateThemeColors colors,
  ) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive ? accent : colors.windowBackground,
            border: Border.all(
              color: isDone || isActive ? accent : colors.border,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : colors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepOne(FoliateThemeColors colors, Color primaryAccent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AppLogo(size: 56),
        const SizedBox(height: 16),
        Text(
          'Welcome to Foliate',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personal, offline-first digital library and modern reader.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: colors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What should we call you?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  filled: true,
                  fillColor: colors.windowBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryAccent, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo(FoliateThemeColors colors, Color primaryAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Books & Library Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose where downloaded books will be saved. Any EPUBs in this directory will be indexed automatically.',
          style: TextStyle(
            fontSize: 13,
            color: colors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Storage selection card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.windowBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _selectedFolderPath != null
                        ? Icons.folder_rounded
                        : Icons.folder_special_rounded,
                    color: primaryAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFolderPath != null
                              ? 'Custom Library Folder'
                              : 'Default Library Storage',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedFolderPath ??
                              'Standard app storage (Internal documents/books)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(
                      _selectedFolderPath != null ? 'Change Folder' : 'Choose Folder',
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_selectedFolderPath != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFolderPath = null;
                          _discoveredBooksCount = 0;
                        });
                      },
                      child: const Text('Reset to Default'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        if (_discoveredBooksCount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryAccent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 18, color: primaryAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Found $_discoveredBooksCount EPUB book${_discoveredBooksCount == 1 ? '' : 's'} ready to import',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Action buttons
        Row(
          children: [
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isScanning ? null : _finishOnboarding,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isScanning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Start Reading',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
