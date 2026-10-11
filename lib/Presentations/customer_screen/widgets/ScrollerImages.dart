// lib/core/constants/scroller_images.dart

class ScrollerImages {
  // ✅ All images for scroller (dummy UI)
  static final List<String> allImages = [
    'assets/images/customerUI/acrepair.png',
    'assets/images/customerUI/bikerepair.png',
    'assets/images/customerUI/building.png',
    'assets/images/customerUI/car machanic.png',
    'assets/images/customerUI/carrepair.png',
    'assets/images/customerUI/electrician.png',
    'assets/images/customerUI/gyser.png',
    'assets/images/customerUI/messon.png',
    'assets/images/customerUI/petroleum.png',
    'assets/images/customerUI/plumber.png',
    'assets/images/customerUI/rcc.png',
    'assets/images/customerUI/refrigerator.png',
    'assets/images/customerUI/solarinstall.png',
    'assets/images/customerUI/washingmachine.png',
  ];

  // ✅ Get first 8 images (or any number you want)
  static List<String> getFeaturedImages() {
    return allImages;
  }

  // ✅ Get random images
  static List<String> getRandomImages({int count = 8}) {
    final shuffled = List<String>.from(allImages)..shuffle();
    return shuffled.take(count).toList();
  }
}