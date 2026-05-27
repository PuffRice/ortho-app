import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  SupabaseClient get client {
    final current = _client;
    if (current == null) {
      throw StateError('SupabaseService has not been initialized.');
    }
    return current;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  // User methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? getCurrentUser() {
    if (!isInitialized) {
      return null;
    }
    return client.auth.currentUser;
  }

  // Expense methods
  Future<List<Map<String, dynamic>>> getExpenses({String? userId}) async {
    final response = await client
        .from('expenses')
        .select()
        .eq('user_id', userId ?? getCurrentUser()!.id)
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    required String description,
  }) async {
    await client.from('expenses').insert({
      'user_id': getCurrentUser()!.id,
      'category': category,
      'amount': amount,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Savings goals methods
  Future<List<Map<String, dynamic>>> getSavingsGoals({String? userId}) async {
    final response = await client
        .from('savings_goals')
        .select()
        .eq('user_id', userId ?? getCurrentUser()!.id);
    return response;
  }

  Future<void> addSavingsGoal({
    required String name,
    required double target,
    required double current,
  }) async {
    await client.from('savings_goals').insert({
      'user_id': getCurrentUser()!.id,
      'name': name,
      'target': target,
      'current': current,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Budget methods
  Future<List<Map<String, dynamic>>> getBudgets({String? userId}) async {
    final response = await client
        .from('budgets')
        .select()
        .eq('user_id', userId ?? getCurrentUser()!.id);
    return response;
  }

  Future<void> addBudget({
    required String category,
    required double limit,
    required String period,
  }) async {
    await client.from('budgets').insert({
      'user_id': getCurrentUser()!.id,
      'category': category,
      'limit': limit,
      'period': period,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Rewards methods
  Future<List<Map<String, dynamic>>> getRewards() async {
    final response = await client
        .from('rewards')
        .select()
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> claimReward({
    required String rewardId,
    required int pointsCost,
  }) async {
    final userId = getCurrentUser()!.id;

    // Update user points
    await client.from('user_profiles').update({
      'points': client.rpc('decrement_points', params: {'amount': pointsCost})
    }).eq('user_id', userId);

    // Record reward claim
    await client.from('reward_claims').insert({
      'user_id': userId,
      'reward_id': rewardId,
      'claimed_at': DateTime.now().toIso8601String(),
    });
  }

  // User profile methods
  Future<Map<String, dynamic>?> getUserProfile({String? userId}) async {
    final response = await client
        .from('user_profiles')
        .select()
        .eq('user_id', userId ?? getCurrentUser()!.id)
        .single();
    return response as Map<String, dynamic>?;
  }

  Future<void> updateUserProfile({
    required String name,
    String? avatarUrl,
  }) async {
    await client.from('user_profiles').update({
      'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', getCurrentUser()!.id);
  }
}
