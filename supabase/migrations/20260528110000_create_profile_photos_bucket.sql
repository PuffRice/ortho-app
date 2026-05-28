insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-photos',
  'profile-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "profile photos public read" on storage.objects;
drop policy if exists "profile photos anon insert" on storage.objects;
drop policy if exists "profile photos anon update" on storage.objects;
drop policy if exists "profile photos anon delete" on storage.objects;

create policy "profile photos public read"
on storage.objects for select
using (bucket_id = 'profile-photos');

create policy "profile photos anon insert"
on storage.objects for insert
with check (bucket_id = 'profile-photos');

create policy "profile photos anon update"
on storage.objects for update
using (bucket_id = 'profile-photos')
with check (bucket_id = 'profile-photos');

create policy "profile photos anon delete"
on storage.objects for delete
using (bucket_id = 'profile-photos');
