import 'package:flutter/material.dart';

class StoreLoadingShimmer extends StatefulWidget {
  const StoreLoadingShimmer({super.key});

  @override
  State<StoreLoadingShimmer> createState() => _StoreLoadingShimmerState();
}

class _StoreLoadingShimmerState extends State<StoreLoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Shimmer
                Container(
                  height: 220,
                  color: _colorAnimation.value,
                ),
                
                // Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo Shimmer
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _colorAnimation.value,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                      
                      // Title & Follow
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 150, height: 24, color: _colorAnimation.value),
                            Container(
                              width: 80, height: 36,
                              decoration: BoxDecoration(
                                color: _colorAnimation.value,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Stats Shimmer
                      const SizedBox(height: 16),
                      Container(width: double.infinity, height: 16, color: _colorAnimation.value),
                      const SizedBox(height: 24),
                      
                      // Tabs Shimmer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(width: 60, height: 20, color: _colorAnimation.value),
                          Container(width: 60, height: 20, color: _colorAnimation.value),
                          Container(width: 60, height: 20, color: _colorAnimation.value),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Content Shimmer Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: _colorAnimation.value,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
