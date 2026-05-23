class Expense {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final String description;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final double target;
  final double current;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.target,
    required this.current,
    required this.createdAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target': target,
      'current': current,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get percentageComplete => current / target;
}

class Budget {
  final String id;
  final String userId;
  final String category;
  final double limit;
  final String period;
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limit,
    required this.period,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      limit: (json['limit'] as num).toDouble(),
      period: json['period'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'limit': limit,
      'period': period,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String category;
  final String image;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.category,
    required this.image,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pointsCost: json['points_cost'] as int,
      category: json['category'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points_cost': pointsCost,
      'category': category,
      'image': image,
    };
  }
}

class UserProfile {
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int points;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.points,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int,
      balance: (json['balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'points': points,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
