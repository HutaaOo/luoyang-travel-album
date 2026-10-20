-- 河洛行记 · 单一管理员权限配置
-- 在 Supabase Dashboard -> SQL Editor 中执行本文件。
-- 唯一管理员登录邮箱固定为 admin@luoyang-album.app；网页端输入账号 admin 即映射到这个邮箱。
-- 管理员密码只在 Supabase Auth 后台创建用户时设置，不要写入 GitHub 仓库。

create table if not exists public.travel_media (
  id text primary key,
  location_id text not null,
  day integer not null check (day between 1 and 4),
  name text not null,
  media_type text not null check (media_type in ('image', 'video')),
  storage_path text not null unique,
  caption text not null default '',
  created_at timestamptz not null default now(),
  user_id uuid references auth.users(id) on delete set null
);

-- 第 0 日专用于“车窗手记 · 一路向中原”，第 5 类专用于“杂项”；兼容此前已创建的旧约束。
alter table public.travel_media drop constraint if exists travel_media_day_check;
alter table public.travel_media add constraint travel_media_day_check check (day between 0 and 5);

alter table public.travel_media enable row level security;

-- 授予必要的 SQL 操作能力；真正的写入权限还会由下面的 RLS 策略二次限制。
grant select on public.travel_media to anon, authenticated;
grant insert, update, delete on public.travel_media to authenticated;
revoke insert, update, delete on public.travel_media from anon;

-- 清理旧版“所有登录成员可写”的策略，避免旧策略与管理员策略叠加。
drop policy if exists "Public can view travel media" on public.travel_media;
drop policy if exists "Family members can add travel media" on public.travel_media;
drop policy if exists "Family members can delete travel media" on public.travel_media;
drop policy if exists "Admin can view travel media" on public.travel_media;
drop policy if exists "Admin can add travel media" on public.travel_media;
drop policy if exists "Admin can edit travel media" on public.travel_media;
drop policy if exists "Admin can delete travel media" on public.travel_media;
drop policy if exists "Restrict media inserts to admin" on public.travel_media;
drop policy if exists "Restrict media updates to admin" on public.travel_media;
drop policy if exists "Restrict media deletes to admin" on public.travel_media;

create policy "Public can view travel media"
  on public.travel_media for select
  to anon, authenticated
  using (true);

create policy "Admin can add travel media"
  on public.travel_media for insert
  to authenticated
  with check (
    (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
    and auth.uid() = user_id
  );

create policy "Admin can edit travel media"
  on public.travel_media for update
  to authenticated
  using ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app')
  with check ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app');

create policy "Admin can delete travel media"
  on public.travel_media for delete
  to authenticated
  using ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app');

-- Restrictive guard 可确保即使未来增加了其他 permissive 策略，写入也仍然只能由管理员完成。
create policy "Restrict media inserts to admin"
  on public.travel_media as restrictive for insert
  to authenticated
  with check ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app');

create policy "Restrict media updates to admin"
  on public.travel_media as restrictive for update
  to authenticated
  using ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app')
  with check ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app');

create policy "Restrict media deletes to admin"
  on public.travel_media as restrictive for delete
  to authenticated
  using ((select auth.jwt() ->> 'email') = 'admin@luoyang-album.app');

-- 公共读取、管理员上传与删除文件。
insert into storage.buckets (id, name, public)
values ('luoyang-travel-album', 'luoyang-travel-album', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Public can view travel album files" on storage.objects;
drop policy if exists "Family members can upload travel album files" on storage.objects;
drop policy if exists "Family members can delete travel album files" on storage.objects;
drop policy if exists "Admin can view travel album files" on storage.objects;
drop policy if exists "Admin can upload travel album files" on storage.objects;
drop policy if exists "Admin can delete travel album files" on storage.objects;
drop policy if exists "Restrict travel album uploads to admin" on storage.objects;
drop policy if exists "Restrict travel album deletes to admin" on storage.objects;
drop policy if exists "Restrict travel album updates to admin" on storage.objects;

create policy "Public can view travel album files"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'luoyang-travel-album');

create policy "Admin can upload travel album files"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'luoyang-travel-album'
    and (storage.foldername(name))[1] = auth.uid()::text
    and (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
  );

create policy "Admin can delete travel album files"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'luoyang-travel-album'
    and (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
  );

-- 对指定相册桶增加 restrictive 守卫，其他 Storage 桶的策略不受影响。
create policy "Restrict travel album uploads to admin"
  on storage.objects as restrictive for insert
  to authenticated
  with check (
    bucket_id <> 'luoyang-travel-album'
    or (
      (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
      and (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy "Restrict travel album deletes to admin"
  on storage.objects as restrictive for delete
  to authenticated
  using (
    bucket_id <> 'luoyang-travel-album'
    or (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
  );

create policy "Restrict travel album updates to admin"
  on storage.objects as restrictive for update
  to authenticated
  using (
    bucket_id <> 'luoyang-travel-album'
    or (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
  )
  with check (
    bucket_id <> 'luoyang-travel-album'
    or (select auth.jwt() ->> 'email') = 'admin@luoyang-album.app'
  );
