class KeywordGenerator {
  /// Generates a list of lowercase searchable keywords based on a string
  static List<String> generateKeywords(String text) {
    if (text.isEmpty) return [];

    final List<String> keywords = [];
    final String cleanText = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    final List<String> words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // Add individual words
    keywords.addAll(words);

    // Add full string
    keywords.add(cleanText);

    // Add progressive substrings for autocomplete support (e.g., "mango" -> "m", "ma", "man", "mang", "mango")
    for (final word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    // Add n-grams
    if (words.length > 1) {
      for (int i = 0; i < words.length - 1; i++) {
        keywords.add('${words[i]} ${words[i + 1]}');
      }
    }

    return keywords.toSet().toList();
  }

  static List<String> generateForEntity({
    required String name,
    List<String> aliases = const [],
    List<String> tags = const [],
    String categoryName = '',
  }) {
    final Set<String> keywords = {};

    keywords.addAll(generateKeywords(name));
    
    if (categoryName.isNotEmpty) {
      keywords.addAll(generateKeywords(categoryName));
    }

    for (var alias in aliases) {
      keywords.addAll(generateKeywords(alias));
    }

    for (var tag in tags) {
      keywords.addAll(generateKeywords(tag));
    }

    return keywords.toList();
  }
}
