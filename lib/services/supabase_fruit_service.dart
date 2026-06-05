import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fruit_database_model.dart';

/// Service untuk fetch fruit data dari Supabase
class SupabaseFruitService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache untuk avoid repeated queries
  static final Map<String, FruitCharacteristics> _fruitCharCache = {};
  static final Map<String, List<RipenessLevelData>> _ripenessLevelCache = {};

  /// Fetch fruit characteristics dari database
  /// Returns null kalau fruit tidak ada di database
  static Future<FruitCharacteristics?> getFruitCharacteristics(
    String fruitName,
  ) async {
    try {
      // Check cache dulu
      if (_fruitCharCache.containsKey(fruitName)) {
        print('[Cache Hit] FruitCharacteristics: $fruitName');
        return _fruitCharCache[fruitName];
      }

      // Query Supabase
      final response = await _supabase
          .from('fruit_characteristics')
          .select()
          .eq('fruit_name', fruitName.toLowerCase())
          .single();

      if (response != null) {
        final fruitChar = FruitCharacteristics.fromJson(response);
        _fruitCharCache[fruitName] = fruitChar;
        print('[DB Query] Fetched FruitCharacteristics: $fruitName');
        return fruitChar;
      }

      return null;
    } catch (e) {
      print('[Error] getFruitCharacteristics($fruitName): $e');
      return null;
    }
  }

  /// Fetch ripeness levels untuk buah tertentu
  static Future<List<RipenessLevelData>> getRipenessLevels(
    String fruitName,
  ) async {
    try {
      // Check cache
      if (_ripenessLevelCache.containsKey(fruitName)) {
        print('[Cache Hit] RipenessLevels: $fruitName');
        return _ripenessLevelCache[fruitName]!;
      }

      final fruitId = await _getFruitId(fruitName);
      if (fruitId == null) {
        return [];
      }

      // Query Supabase
      final response = await _supabase
          .from('ripeness_levels')
          .select()
          .eq('fruit_id', fruitId)
          .order('ripeness_score_min', ascending: true);

      if (response != null && response is List) {
        final levels = (response as List)
            .map((json) => RipenessLevelData.fromJson(json as Map<String, dynamic>))
            .toList();
        _ripenessLevelCache[fruitName] = levels;
        print('[DB Query] Fetched RipenessLevels: $fruitName (${levels.length} levels)');
        return levels;
      }

      return [];
    } catch (e) {
      print('[Error] getRipenessLevels($fruitName): $e');
      return [];
    }
  }

  /// Internal: get fruit ID dari fruit_name
  static Future<String?> _getFruitId(String fruitName) async {
    try {
      final response = await _supabase
          .from('fruit_characteristics')
          .select('id')
          .eq('fruit_name', fruitName.toLowerCase())
          .single();

      return response['id'] as String?;
    } catch (e) {
      print('[Error] _getFruitId($fruitName): $e');
      return null;
    }
  }

  /// Fetch both characteristics dan ripeness levels sekaligus
  /// More efficient untuk detection flow
  static Future<({FruitCharacteristics? characteristics, List<RipenessLevelData> levels})> 
  getFruitData(String fruitName) async {
    try {
      final characteristics = await getFruitCharacteristics(fruitName);
      final levels = await getRipenessLevels(fruitName);

      return (characteristics: characteristics, levels: levels);
    } catch (e) {
      print('[Error] getFruitData($fruitName): $e');
      return (characteristics: null as FruitCharacteristics?, levels: <RipenessLevelData>[]);
    }
  }

  /// Check if fruit exists di database
  static Future<bool> fruitExists(String fruitName) async {
    try {
      final response = await _supabase
          .from('fruit_characteristics')
          .select('id')
          .eq('fruit_name', fruitName.toLowerCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('[Error] fruitExists($fruitName): $e');
      return false;
    }
  }

  /// Get list semua fruits yang tersedia di database
  static Future<List<String>> getAvailableFruits() async {
    try {
      // Check cache dulu dengan key 'all_fruits'
      if (_fruitCharCache.containsKey('all_fruits')) {
        final cached = _fruitCharCache['all_fruits'] as FruitCharacteristics?;
        if (cached != null) {
          // Ini hack, seharusnya fetch full list dulu
          print('[Cache Hit] AvailableFruits');
        }
      }

      final response = await _supabase
          .from('fruit_characteristics')
          .select('fruit_name');

      if (response != null && response is List) {
        return (response as List)
            .map((item) => (item as Map<String, dynamic>)['fruit_name'] as String)
            .toList();
      }

      return [];
    } catch (e) {
      print('[Error] getAvailableFruits(): $e');
      return [];
    }
  }

  /// Clear cache (useful untuk testing atau update)
  static void clearCache() {
    _fruitCharCache.clear();
    _ripenessLevelCache.clear();
    print('[Cache] Cleared all caches');
  }

  /// Clear cache untuk specific fruit
  static void clearFruitCache(String fruitName) {
    _fruitCharCache.remove(fruitName);
    _ripenessLevelCache.remove(fruitName);
    print('[Cache] Cleared cache for $fruitName');
  }

  /// Get cache statistics (untuk debugging)
  static Map<String, int> getCacheStats() {
    return {
      'fruitChar_items': _fruitCharCache.length,
      'ripenessLevel_items': _ripenessLevelCache.length,
    };
  }
}
