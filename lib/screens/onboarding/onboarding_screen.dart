// onboarding_with_animations.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Gradient & ButtonShadow constants (copied from login screen)
const LinearGradient kBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

/// --- OnboardingScreen with logo scale-pop animation ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.7)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logoController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) => Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(0, 66, 134, 244),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                const Text(
                  'Elevate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Personalized Brain Training',
                  style: TextStyle(color: Colors.white60, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/onboarding-slides'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      shadowColor: const Color(0xFF38BDF8).withOpacity(0.6),
                      elevation: 12,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/login'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Already a member? Sign in',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// --- OnboardingSlidesScreen with 3D tilt per page ---
class OnboardingSlidesScreen extends StatefulWidget {
  const OnboardingSlidesScreen({super.key});

  @override
  State<OnboardingSlidesScreen> createState() => _OnboardingSlidesScreenState();
}

class _OnboardingSlidesScreenState extends State<OnboardingSlidesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<SlideData> _slides = [
    SlideData(
      title: "Challenge your mind",
      description:
      "Play 40+ brain games to improve your vocabulary, communication, memory skills, and more.",
      imagePath: "assets/gifs/chatbot.gif",
    ),
    SlideData(
      title: "Track your progress",
      description:
      "Measure your mental fitness, identify areas of growth, and celebrate your accomplishments.",
      imagePath: "assets/gifs/progress.gif",
    ),
    SlideData(
      title: "See the benefits",
      description:
      "Improve your productivity, learning power, and self-confidence with games developed by educational experts.",
      imagePath: "assets/gifs/process.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_currentPage > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/onboarding');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final page = _pageController.hasClients
                        ? (_pageController.page ?? _pageController.initialPage.toDouble())
                        : 0.0;
                    final delta = (index - page).clamp(-1.0, 1.0);
                    final scale = (1 - delta.abs() * 0.08).clamp(0.92, 1.0);
                    final slide = _slides[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          Transform.scale(
                            scale: scale,
                            child: _buildSlideImage(slide),
                          ),
                          const Spacer(flex: 3), // Increased space before title
                          Text(
                            slide.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20), // Increased space after title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              slide.description,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.5
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Spacer(flex: 2), // Increased space before button
                          if (index == _slides.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 40), // Button raised
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => context.push('/before-sign-up'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF38BDF8),
                                    shadowColor: const Color(0xFF38BDF8).withOpacity(0.6),
                                    elevation: 12,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (index != _slides.length - 1) const Spacer(flex: 3),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildPageIndicator(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideImage(SlideData slide) {
    if (slide.imagePath != null && slide.imagePath!.isNotEmpty) {
      return Container(
        width: 280, // Slightly reduced for better balance
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.asset(
          slide.imagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
        ),
      );
    }
    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() => Container(
    width: 200, // Reduced
    height: 200,
    decoration: BoxDecoration(
      color: const Color(0xFF38BDF8),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Icon(Icons.school, size: 80, color: Colors.white),
  );

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? const Color(0xFF38BDF8) : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// SlideData model
class SlideData {
  final String title;
  final String description;
  final String? imagePath;

  SlideData({
    required this.title,
    required this.description,
    this.imagePath,
  });
}