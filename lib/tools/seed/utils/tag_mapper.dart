class TagMapper {
  static final List<Map<String, dynamic>> predefinedTags = [
    {'name': 'Spicy', 'icon': '🌶️', 'isFilterable': true},
    {'name': 'Sweet', 'icon': '🍬', 'isFilterable': true},
    {'name': 'Homemade', 'icon': '🏠', 'isFilterable': true},
    {'name': 'Organic', 'icon': '🌱', 'isFilterable': true},
    {'name': 'Traditional', 'icon': '🏺', 'isFilterable': true},
    {'name': 'Preservative Free', 'icon': '✨', 'isFilterable': true},
    {'name': 'Healthy', 'icon': '💪', 'isFilterable': true},
    {'name': 'Millet Based', 'icon': '🌾', 'isFilterable': true},
    {'name': 'Handcrafted', 'icon': '👐', 'isFilterable': true},
    {'name': 'Vegan', 'icon': '🌿', 'isFilterable': true},
    {'name': 'Gluten Free', 'icon': '🌾', 'isFilterable': true},
    {'name': 'Festival Special', 'icon': '🎊', 'isFilterable': true},
  ];

  static List<String> autoMapTagsForCategory(String categoryName) {
    final lowerCat = categoryName.toLowerCase();
    final List<String> tags = ['Homemade', 'Preservative Free']; // Default tags

    if (lowerCat.contains('pickle') || lowerCat.contains('masala') || lowerCat.contains('podi')) {
      tags.add('Spicy');
      tags.add('Traditional');
    }
    
    if (lowerCat.contains('sweet') || lowerCat.contains('chocolate') || lowerCat.contains('honey') || lowerCat.contains('jaggery')) {
      tags.add('Sweet');
    }
    
    if (lowerCat.contains('millet') || lowerCat.contains('healthy') || lowerCat.contains('nutrition') || lowerCat.contains('ayurvedic')) {
      tags.add('Healthy');
      if (lowerCat.contains('millet')) tags.add('Millet Based');
    }

    if (lowerCat.contains('organic')) {
      tags.add('Organic');
    }

    if (lowerCat.contains('festive') || lowerCat.contains('combo')) {
      tags.add('Festival Special');
    }

    return tags.toSet().toList();
  }
}
