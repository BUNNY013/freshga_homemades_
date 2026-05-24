import 'package:freshga_homemades/tools/seed/seed_database.dart';

void main() async {
  final seeder = DatabaseSeeder();
  print("Testing categories...");
  await seeder.seedCategories();
  print("Testing subcategories...");
  await seeder.seedSubcategories();
  print("Testing banners...");
  await seeder.seedBanners();
  print("Testing collections...");
  await seeder.seedCollections();
  print("Testing trust features...");
  await seeder.seedTrustFeatures();
  print("Testing home sections...");
  await seeder.seedHomeSections();
  print("Testing stores and products...");
  await seeder.seedStoresAndProducts();
  print("Done!");
}
