import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  print("Starting debug fetch...");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  
  try {
    final subCats = await db.collection('sub_categories').get();
    print("sub_categories count: ${subCats.docs.length}");
    if (subCats.docs.isNotEmpty) {
      print("Sample sub_category:");
      print(subCats.docs.first.data());
    }
    
    final subcatsOld = await db.collection('subcategories').get();
    print("subcategories (no underscore) count: ${subcatsOld.docs.length}");
    
    final cats = await db.collection('categories').get();
    print("categories count: ${cats.docs.length}");
    if (cats.docs.isNotEmpty) {
      print("Sample category:");
      print(cats.docs.first.data());
    }
  } catch (e) {
    print("Error fetching: $e");
  }
}
