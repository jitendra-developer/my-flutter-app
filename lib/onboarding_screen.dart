import 'settings_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/utils/app_localization.dart';
import 'dart:developer' as developer;


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  List<Map<String, String>> onboardingSlides = [];
  bool isLoading = true;

  Future<void> loadSettings() async {
    try {
      final service = SettingsService();
      final data = await service.getOnboardingSettings();

      // The API returns a Map<String, String> of keys and values.
      // We need to group them into slides: onboarding_slide1_title, onboarding_slide1_text, etc.
      final List<Map<String, String>> slides = [];
      
      // We'll iterate up to 10 potential slides
      for (int i = 1; i <= 10; i++) {
        final prefix = 'onboarding_slide$i';
        final active = data['${prefix}_active'];
        
        // If the slide is explicitly marked as inactive (0), we skip it.
        // If the key is missing but we have a title/text, we might show it as fallback,
        // but the doc says 1=active, 0=inactive.
        if (active == '0') continue;

        final title = data['${prefix}_title'];
        final text = data['${prefix}_text'];
        final image = data['${prefix}_image'];

        if (title != null || text != null || image != null) {
          slides.add({
            'title': title ?? '',
            'text': text ?? '',
            'image': image ?? '',
            'index': i.toString(),
          });
        }
      }

      setState(() {
        onboardingSlides = slides;
        isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading onboarding settings', error: e);
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
   super.initState();
   loadSettings();
  }

 @override
  Widget build(BuildContext context) {
    if (isLoading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
    }
    final l10n = AppLocalization('en');

    // Slide count
    final int slideCount = onboardingSlides.isNotEmpty ? onboardingSlides.length : 3;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: slideCount,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              if (onboardingSlides.isNotEmpty) {
                final slide = onboardingSlides[index];
                return _buildPage(
                  imagePath: slide['image'],
                  title: slide['title']!.isNotEmpty ? slide['title']! : l10n.translate("onboarding_slide${slide['index']}_title"),
                  subtitle: slide['text']!.isNotEmpty ? slide['text']! : l10n.translate("onboarding_slide${slide['index']}_subtitle"),
                  fallbackIcon: _getIconForIndex(int.parse(slide['index']!)),
                );
              } else {
                // Fallback to localized slides if no data from API
                return _buildPage(
                  imagePath: null,
                  title: l10n.translate("onboarding_slide${index + 1}_title"),
                  subtitle: l10n.translate("onboarding_slide${index + 1}_subtitle"),
                  fallbackIcon: _getIconForIndex(index + 1),
                );
              }
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                else
                  const SizedBox(width: 48), // Spacer for balance
                if (_currentPage < slideCount - 1)
                  IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(l10n.translate('get_started')),
                  ),
              ],
            ),
          ),
          if (_currentPage < slideCount - 1)
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: Text(
                  l10n.translate('skip'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 1: return Icons.auto_awesome;
      case 2: return Icons.dashboard_customize;
      case 3: return Icons.bolt;
      default: return Icons.star;
    }
  }

  Widget _buildPage({
    String? imagePath,
    required String title,
    required String subtitle,
    required IconData fallbackIcon,
  }) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [

     Container(
       width: 260,
       height: 260,
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(24),
         color: Colors.white,
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.4),
             blurRadius: 20,
             offset: const Offset(0, 10),
           ),
         ],
       ),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(24),
         child: (imagePath != null && imagePath.isNotEmpty)
           ? Image.network(
               imagePath,
               fit: BoxFit.cover,
               loadingBuilder: (context, child, progress) {
                 if (progress == null) return child;
                 return const Center(child: CircularProgressIndicator());
               },
               errorBuilder: (context, error, stackTrace) {
                 return Icon(fallbackIcon, size: 100, color: const Color(0xFF3B2E7E));
               },
             )
           : Container(
               color: const Color(0xFF1C1C24),
               child: Icon(fallbackIcon, size: 100, color: const Color(0xFF4A60D4)),
             ),
       ),
     ),

      const SizedBox(height: 40),

      Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),

      const SizedBox(height: 10),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ),
    ],
  );
}
}
