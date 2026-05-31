class SlugGenerator {
  static String generate(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove special characters
        .trim()
        .replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with hyphens
  }
}
