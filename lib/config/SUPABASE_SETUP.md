# Ortho : Intelligent Finances Flutter App

A comprehensive finance tracking application built with Flutter, featuring spending analytics, savings goals, budgeting tools, and a rewards system. Built with Supabase as the backend.

## Features

- **Home Screen**: Overview of balance, savings, reward points, and quick actions
- **Dashboard**: Spending analytics, budget tracking, and achievement badges
- **Rewards**: Redeem points for various rewards and vouchers
- **Profile**: User settings, payment methods, and preferences
- **Cross-platform**: Works on Android, iOS, and Web

## Setup Instructions

### Prerequisites
- Flutter SDK installed
- Supabase account (https://supabase.com)

### 1. Create Supabase Project

1. Go to [Supabase](https://supabase.com) and create a new project
2. Note your `Project URL` and `Anon Key` from the API settings

### 2. Create Database Tables

Run the following SQL in your Supabase SQL editor:

```sql
-- User Profiles Table
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL UNIQUE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  points INT DEFAULT 0,
  balance DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- Expenses Table
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  category TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Savings Goals Table
CREATE TABLE savings_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  name TEXT NOT NULL,
  target DECIMAL(10, 2) NOT NULL,
  current DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT now()
);

-- Budgets Table
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  category TEXT NOT NULL,
  limit DECIMAL(10, 2) NOT NULL,
  period TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

-- Rewards Table
CREATE TABLE rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points_cost INT NOT NULL,
  category TEXT NOT NULL,
  image TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Reward Claims Table
CREATE TABLE reward_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  reward_id UUID REFERENCES rewards(id) NOT NULL,
  claimed_at TIMESTAMP DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_claims ENABLE ROW LEVEL SECURITY;

-- Create Policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Create Policies for expenses
CREATE POLICY "Users can view own expenses" ON expenses
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own expenses" ON expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create Policies for savings_goals
CREATE POLICY "Users can view own goals" ON savings_goals
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON savings_goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create Policies for budgets
CREATE POLICY "Users can view own budgets" ON budgets
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budgets" ON budgets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create Policies for rewards
CREATE POLICY "Anyone can view rewards" ON rewards
  FOR SELECT USING (true);

-- Create Policies for reward_claims
CREATE POLICY "Users can view own claims" ON reward_claims
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can claim rewards" ON reward_claims
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 3. Configure Flutter App

1. Update your Supabase credentials in your code (for now, before authentication is implemented):

Create a new file `lib/config/supabase_config.dart`:

```dart
const String SUPABASE_URL = 'your-supabase-url';
const String SUPABASE_ANON_KEY = 'your-anon-key';
```

2. Update `lib/main.dart` to initialize Supabase:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService().initialize(
    supabaseUrl: SUPABASE_URL,
    supabaseAnonKey: SUPABASE_ANON_KEY,
  );
  
  runApp(const MainApp());
}
```

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Run the App

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                    # App entry point & navigation
├── screens/
│   ├── home_screen.dart         # Home/Dashboard view
│   ├── dashboard_screen.dart    # Analytics & budgets
│   ├── rewards_screen.dart      # Rewards marketplace
│   └── profile_screen.dart      # User profile & settings
├── services/
│   └── supabase_service.dart    # Supabase integration
├── models/
│   └── models.dart              # Data models
└── config/
    └── supabase_config.dart     # Supabase credentials
```

## Next Steps

1. **Authentication**: Implement sign-up/login functionality
2. **Data Persistence**: Connect screens to Supabase data
3. **Real-time Updates**: Add Supabase real-time subscriptions
4. **Image Upload**: Implement avatar/receipt image uploads
5. **Push Notifications**: Add Firebase Cloud Messaging
6. **Advanced Charts**: Replace basic charts with more advanced analytics

## Technologies Used

- **Flutter**: UI framework
- **Supabase**: Backend & database
- **Dart**: Programming language
- **Material Design**: UI design system

## License

This project is open source and available under the MIT License.
