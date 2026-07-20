import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize({required String url, required String anonKey}) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  Future<List<Map<String, dynamic>>> select(String table, {String? column, String? filter, dynamic value}) async {
    var query = client.from(table).select();
    if (column != null && filter != null) {
      query = query.eq(column, value);
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response as List<dynamic>);
  }

  Future<Map<String, dynamic>?> insert(String table, Map<String, dynamic> data) async {
    final response = await client.from(table).insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> update(String table, Map<String, dynamic> data, {required String column, required dynamic value}) async {
    await client.from(table).update(data).eq(column, value);
  }

  Future<void> delete(String table, {required String column, required dynamic value}) async {
    await client.from(table).delete().eq(column, value);
  }
}
