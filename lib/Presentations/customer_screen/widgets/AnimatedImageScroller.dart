// lib/Presentations/customer_screen/widgets/animated_image_scroller.dart

import 'package:flutter/material.dart';

class AnimatedImageScroller extends StatefulWidget {
  final List<String> imagePaths;
  final double height;
  final Duration animationDuration;

  const AnimatedImageScroller({
    super.key,
    required this.imagePaths,
    this.height = 120,
    this.animationDuration = const Duration(milliseconds: 8000),
  });

  @override
  State<AnimatedImageScroller> createState() => _AnimatedImageScrollerState();
}

class _AnimatedImageScrollerState extends State<AnimatedImageScroller>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<String> _imagePaths;

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.imagePaths);

    // ✅ Duplicate images for seamless loop
    _imagePaths.addAll(widget.imagePaths);

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // ✅ Calculate scroll offset (right to left)
            final double itemWidth = widget.height * 1.2;
            final double totalWidth = _imagePaths.length * itemWidth;
            final double offset = _animation.value * (totalWidth / 2);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              controller: _createScrollController(offset),
              child: Row(
                children: _imagePaths.map((path) {
                  return _buildImageItem(path, itemWidth);
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ Create scroll controller with custom offset
  ScrollController _createScrollController(double offset) {
    final controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.jumpTo(offset);
    });
    return controller;
  }

  // ✅ Build single image item
  Widget _buildImageItem(String path, double width) {
    return Container(
      width: width,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey[400],
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }
}