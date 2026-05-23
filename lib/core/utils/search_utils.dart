class SearchUtils {
  /// Generates a list of prefix-based searchable keywords from a given text.
  /// 
  /// Example: "Wild Forest Honey"
  /// Returns: ["w", "wi", "wil", "wild", "f", "fo", "for", "forest", "h", "ho", "hon", "hone", "honey", "wild honey", "forest honey"]
  static List<String> generateSearchKeywords(String text) {
    if (text.isEmpty) return [];

    final String cleanedText = text.toLowerCase().trim();
    final List<String> words = cleanedText.split(RegExp(r'\s+'));
    final Set<String> keywords = {};

    // 1. Generate prefixes for each individual word
    for (String word in words) {
      if (word.isEmpty) continue;
      String currentPrefix = '';
      for (int i = 0; i < word.length; i++) {
        currentPrefix += word[i];
        keywords.add(currentPrefix);
      }
    }

    // 2. Generate multi-word prefixes (e.g. "wild h", "wild ho")
    // For combinations starting with subsequent words, like "forest honey"
    for (int i = 0; i < words.length; i++) {
      String phrase = '';
      for (int j = i; j < words.length; j++) {
        if (phrase.isEmpty) {
          phrase = words[j];
        } else {
          phrase = '$phrase ${words[j]}';
        }
        
        // Add the exact multi-word phrase
        keywords.add(phrase);
        
        // If it's a long phrase, we don't necessarily need every single character prefix of the entire phrase
        // But for exact searches it's useful. We already added individual word prefixes.
        // Let's add prefixes for the phrase itself to support typing "wild ho"
        String currentPhrasePrefix = '';
        for (int k = 0; k < phrase.length; k++) {
           currentPhrasePrefix += phrase[k];
           keywords.add(currentPhrasePrefix);
        }
      }
    }

    return keywords.toList();
  }
}
