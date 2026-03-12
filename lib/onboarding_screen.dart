import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  Map<String, String> settings = {};
  bool isLoading = true;
 
  Future<void> loadSettings() async {
    final service = SettingsService();

    final data = await service.getSettings();

    setState(() {
      settings = data;
      isLoading = false;
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildPage(
                imagePath: settings["onboarding_slide1_image"],
                title: settings["onboarding_slide1_title"] ?? "Welcome to Vakya Pro",
                subtitle: settings["onboarding_slide1_text"] ?? "Generate perfect prompts to maximize the power of any AI tool.",
                fallbackIcon: Icons.auto_awesome,
              ),
              _buildPage(
                imagePath: settings["onboarding_slide2_image"],
                title: settings["onboarding_slide2_title"] ?? "For Every AI Platform",
                subtitle: settings["onboarding_slide2_text"] ?? "Optimized prompts for ChatGPT, Midjourney, Claude, and more.",
                fallbackIcon: Icons.dashboard_customize,
              ),
              _buildPage(
                imagePath: settings["onboarding_slide3_image"],
                title: settings["onboarding_slide3_title"] ?? "Easy to Use",
                subtitle: settings["onboarding_slide3_text"] ?? "Just describe what you need, and let our AI build the prompt for you.",
                fallbackIcon: Icons.bolt,
              ),
            ],
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
                if (_currentPage < 2)
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
                    child: const Text('Get Started'),
                  ),
              ],
            ),
          ),
          if (_currentPage < 3)
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
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
