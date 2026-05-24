create table if not exists users (
  id text primary key,
  email text not null,
  display_name text not null,
  photo_url text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create table if not exists accounts (
  id text primary key,
  user_id text not null references users(id),
  name text not null,
  type text not null,
  currency text not null,
  opening_balance numeric not null,
  current_balance numeric not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index if not exists accounts_user_id_idx on accounts(user_id);

create table if not exists categories (
  id text primary key,
  user_id text not null references users(id),
  name text not null,
  type text not null,
  icon text,
  color integer,
  sort_order integer not null default 0,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index if not exists categories_user_id_idx on categories(user_id);

create table if not exists transactions (
  id text primary key,
  user_id text not null references users(id),
  account_id text not null references accounts(id),
  category_id text not null references categories(id),
  type text not null,
  amount numeric not null,
  currency text not null,
  date timestamptz not null,
  note text,
  is_recurring boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index if not exists transactions_user_id_idx on transactions(user_id);
create index if not exists transactions_date_idx on transactions(date);

create table if not exists transfers (
  id text primary key,
  user_id text not null references users(id),
  from_account_id text not null references accounts(id),
  to_account_id text not null references accounts(id),
  amount numeric not null,
  date timestamptz not null,
  note text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index if not exists transfers_user_id_idx on transfers(user_id);

create table if not exists budgets (
  id text primary key,
  user_id text not null references users(id),
  category_id text references categories(id),
  period text not null,
  amount numeric not null,
  start_date timestamptz not null,
  end_date timestamptz,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index if not exists budgets_user_id_idx on budgets(user_id);

create table if not exists recurring_transactions (
  id text primary key,
  user_id text not null references users(id),
  account_id text not null references accounts(id),
  category_id text not null references categories(id),
  type text not null,
  amount numeric not null,
  interval text not null,
  next_run_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);
create index if not exists recurring_user_id_idx on recurring_transactions(user_id);
