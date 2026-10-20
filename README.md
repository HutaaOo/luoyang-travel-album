# 河洛行记 · 四日山水旅行相册

这是一个无需构建工具、可直接部署到 GitHub Pages 的旅行影集。视觉采用暖宣纸、墨绿、朱砂与鎏金配色。除白马寺、洛阳古墓博物馆、少林寺、龙门石窟、老君山、清明上河园六个目的地外，还设有“车窗手记 · 一路向中原”与最后一栏“杂项”。前者用于收藏坐火车启程途中拍摄的田野、站台与窗外风景；“杂项”用于保存不属于固定景点的随手拍、食物、沿途小景和其他零散回忆。两者都拥有独立卡片和单独筛选，不影响原本四天行程。

## 权限设计

- **访客：** 无需登录，打开网址即可浏览所有已上传照片和视频。
- **唯一管理员：** 账号名为 `admin`。只有该账号可以上传照片 / 视频、替换现有媒体、修改显示名称和说明、删除媒体。
- **密码：** 由 Supabase Auth 校验，不写在 `index.html`、SQL 或 GitHub 仓库中。
- **后端权限：** 数据库与 Storage 的 RLS 策略都限定管理员邮箱 `admin@luoyang-album.app`，不是单靠前端隐藏按钮。

> 本站用 GitHub Pages 做公开前端，用 Supabase 做共享数据和身份验证。云端配置未完成时，管理按钮保持关闭；必须完成云端配置才能让家人通过同一网址共享照片。

## 一、部署到 GitHub Pages

1. 解压下载的 ZIP 文件。
2. 在 GitHub 创建一个新仓库，将 `index.html`、`README.md` 和 `supabase-setup.sql` 上传到仓库根目录。
3. 打开仓库 **Settings → Pages**，在 **Build and deployment** 选择 `Deploy from a branch`，分支选择 `main`，目录选择 `/(root)`，保存。
4. 下一步配置 Supabase 后，再次提交修改好的 `index.html`。

## 二、配置共享相册与管理员账号

### 1. 创建 Supabase 项目

在 [Supabase](https://supabase.com/) 创建项目，然后打开项目的 **SQL Editor**，将本仓库中的 `supabase-setup.sql` 全部复制执行。

该 SQL 会创建媒体数据表、公开读取的 Storage 存储桶，并将写入、替换、修改元数据和删除权限限制为单一管理员邮箱。请在你自己的 Supabase 项目中运行，避免与其他用途的数据表或策略混用。

### 2. 创建唯一管理员

1. 在 Supabase Dashboard 打开 **Authentication → Users**，手动添加一个用户。
2. 邮箱填写：`admin@luoyang-album.app`。
3. 密码栏填写你刚才指定的管理员密码，并在创建用户时启用“确认邮箱 / Auto Confirm User”（这个映射邮箱不用于收信）。密码只保存在 Supabase Auth 中，不会写入项目文件。
4. 在 **Authentication 设置**中关闭公开用户注册（Allow new users to sign up），不要给访客提供注册入口。

网页登录框中输入的用户名是 `admin`；网页会将它映射到上面的管理员邮箱，由 Supabase 验证密码。不要在网页代码或公开 README 里硬编码管理员密码，也不要在前端使用 `service_role` / secret key。

### 3. 填写前端配置

在 Supabase 项目的 API 设置中复制 **Project URL** 和 **anon / publishable key**。编辑 `index.html`，找到：

```js
window.ALBUM_CONFIG = {
  SUPABASE_URL: "",
  SUPABASE_ANON_KEY: "",
  BUCKET: "luoyang-travel-album",
  ADMIN_EMAIL: "admin@luoyang-album.app"
};
```

将 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY` 填上，其他值保持不变。然后将修改后的文件提交到 GitHub，等待 Pages 重新部署。

**只使用 anon / publishable key。绝对不要把 Supabase `service_role` 或 secret key 放到公开网页。** anon / publishable key 本身会公开，真正保护写入权限的是 SQL 中的 RLS 策略。

### 4. 使用方法

- 普通访客直接打开 GitHub Pages 网址，即可浏览全部公开影像，无需登录。
- 管理员点击右上角“管理员登录”，输入账号 `admin` 和在 Supabase 创建用户时设置的密码。
- 登录后，每个目的地、“车窗手记”及最后的“杂项”卡片会出现上传按钮；每张媒体上方会出现编辑、替换和删除操作。
- “编辑”可修改媒体显示名称和说明；“替换”可上传新的照片或视频替换原文件；“删除”会移除影像记录。
- 新增的“杂项”位于所有目的地卡片的最后，可单独筛选并用于存放不属于具体景点的照片或视频。
- 管理完成后点击“退出登录”。访客不需要登录，且不会看到任何管理操作。

## 隐私说明

此配置的 Storage 桶为公开读取，因此所有上传的照片和视频均可通过公开 URL 访问。适合旅行纪念相册，不适合身份证件、家庭住址、票据等敏感文件。如果将来希望相册只对指定家庭成员可见，需要改为私有 bucket 与授权访问链接。

## 文件说明

- `index.html`：网页布局、景点卡片、筛选、媒体预览、管理员登录与管理功能。
- `supabase-setup.sql`：数据库与 Storage 权限策略。
- `README.md`：部署与账号配置说明。
