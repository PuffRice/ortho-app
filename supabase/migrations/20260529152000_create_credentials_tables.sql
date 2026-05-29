create table if not exists payment_card_credentials (
  id text primary key,
  user_id text not null references users(id) on delete cascade,
  bank_name text not null,
  bank_logo_base64 text,
  card_type text not null check (card_type in ('credit', 'debit', 'prepaid')),
  network text not null check (network in ('visa', 'mastercard', 'other')),
  cardholder_name text not null,
  card_number text not null,
  expiry text not null,
  has_nfc boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create index if not exists payment_card_credentials_user_id_idx
  on payment_card_credentials(user_id);

create index if not exists payment_card_credentials_updated_at_idx
  on payment_card_credentials(updated_at);

alter table payment_card_credentials enable row level security;

create policy "Users can view own payment card credentials"
  on payment_card_credentials
  for select
  using (auth.uid()::text = user_id);

create policy "Users can insert own payment card credentials"
  on payment_card_credentials
  for insert
  with check (auth.uid()::text = user_id);

create policy "Users can update own payment card credentials"
  on payment_card_credentials
  for update
  using (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

create table if not exists bank_account_credentials (
  id text primary key,
  user_id text not null references users(id) on delete cascade,
  bank_name text not null,
  bank_logo_base64 text,
  branch_name text not null,
  account_name text not null,
  account_number text not null,
  routing_number text not null,
  swift_code text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create index if not exists bank_account_credentials_user_id_idx
  on bank_account_credentials(user_id);

create index if not exists bank_account_credentials_updated_at_idx
  on bank_account_credentials(updated_at);

alter table bank_account_credentials enable row level security;

create policy "Users can view own bank account credentials"
  on bank_account_credentials
  for select
  using (auth.uid()::text = user_id);

create policy "Users can insert own bank account credentials"
  on bank_account_credentials
  for insert
  with check (auth.uid()::text = user_id);

create policy "Users can update own bank account credentials"
  on bank_account_credentials
  for update
  using (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);
