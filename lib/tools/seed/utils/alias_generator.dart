class AliasGenerator {
  static final Map<String, List<String>> _aliasMap = {
    'mango pickles': ['avakaya', 'aam achar', 'mango achar', 'mavidikaya pachadi'],
    'lemon pickles': ['nimbu achar', 'nimmakaya pachadi'],
    'garlic pickles': ['lahsun achar', 'vellulli pachadi'],
    'tomato pickles': ['tomato nilva pachadi', 'tamatar achar'],
    'gongura pickles': ['gongura pachadi', 'sorrel leaves pickle'],
    'mixed vegetable pickles': ['mix achar', 'mix vegetable pachadi'],
    'chicken pickles': ['kodi pachadi', 'chicken achar'],
    'mutton pickles': ['mutton achar', 'gosht achar'],
    'prawn pickles': ['royyala pachadi', 'jhinga achar'],
    'murukku': ['chakli', 'jantikalu'],
    'mixture': ['namkeen', 'chivda', 'farsan'],
    'sev': ['karapusa', 'omapodi'],
    'laddu': ['laddoo', 'bundi laddu'],
    'kaju katli': ['kaju barfi'],
    'garam masala': ['all spice powder'],
    'gunpowder': ['idli podi', 'kandi podi'],
    'karivepaku podi': ['curry leaf powder'],
    'ghee': ['clarified butter', 'neyyi'],
    'bilona ghee': ['a2 ghee', 'desi cow ghee'],
  };

  static List<String> getAliases(String name) {
    final lowerName = name.toLowerCase().trim();
    if (_aliasMap.containsKey(lowerName)) {
      return _aliasMap[lowerName]!;
    }
    
    // Check for partial matches
    for (final entry in _aliasMap.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return [];
  }
}
