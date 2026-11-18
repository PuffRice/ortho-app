-- Loan tracking. Loans are recorded against an account but never move the
-- account balance or income/expense totals; they only reduce the spendable
-- ("available") amount shown next to the balance on the home screen.
create table if not exists loans (
  id text primary key,
  user_id text not null references users(id) on delete cascade,
  account_id text not null references accounts(id) on delete cascade,
  direction text not null check (direction in ('given', 'taken')),
  counterparty text not null,
  amount numeric not null,
  currency text not null,
  date timestamptz not null,
  settled_amount numeric not null default 0,
  note text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create index if not exists loans_user_id_idx on loans(user_id);
create index if not exists loans_date_idx on loans(date);

alter table loans enable row level security;

create policy "Users can view own loans"
  on loans
  for select
  using (auth.uid()::text = user_id);

create policy "Users can insert own loans"
  on loans
  for insert
  with check (auth.uid()::text = user_id);

create policy "Users can update own loans"
  on loans
  for update
  using (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);
