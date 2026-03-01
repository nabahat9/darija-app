import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_info_screen.dart';
import 'record_screen.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Your specific Navy Blue color
  final Color primaryNavy = const Color.fromARGB(255, 51, 73, 112);

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/about1.png",
      "text": "Record your voice and help research the Darija dialect"
    },
    {
      "image": "assets/about2.png",
      "text": "Every voice matters and contributes to research"
    },
    {
      "image": "assets/about3.png",
      "text": "Join us and make your voice heard by linguists"
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRegistered();
  }

  void _checkUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecordScreen(
            name: prefs.getString('name') ?? '',
            age: prefs.getString('age') ?? '',
            gender: prefs.getString('gender') ?? '',
            userId: userId,
          ),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToUserInfo();
    }
  }

  void _skip() => _goToUserInfo();

  void _goToUserInfo() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UserInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Soft off-white to complement navy
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Page View
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          _pages[index]["image"]!,
                          height: 280,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index]["text"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: primaryNavy,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Middle Section: Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 24 : 8, // Wider active dot
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? primaryNavy
                        : primaryNavy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Bottom Section: Navigation Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Start" : "Next",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
