# Odoo 18 Docker Template

Template deploy Odoo 18 (rakitan sendiri di atas `python:3.12-slim-bookworm`,
source Odoo di-clone dari branch `19.0`, PostgreSQL 16) dengan library
tambahan yang biasa dibutuhkan modul custom.

Sudah termasuk di image:

- Dependency resmi Odoo 18 dari `requirements.txt`
- `pandas`, `sqlparse`, `xlsxwriter`, `requests` (izi_data)
- `odoorpc`, `openupgradelib` (upgrade_analysis)
- `openpyxl` (sql_export_excel)
- `paramiko`, `boto3`, `dropbox`, `pyncclient`, `nextcloud-api-wrapper`
  (auto_database_backup)
- `pycryptodomex` (izi_tokopedia)
- `mysql-connector-python`, `gspread`, `oauth2client` (izi_data_lib_*)
- `pymssql` (izi_data_lib_mssql)

Karena library dibakukan di Dockerfile, container boleh di-recreate
kapan pun tanpa kehilangan apa pun — tidak ada lagi pip manual di
container yang berjalan.

## Cara pakai

```bash
git clone <repo-ini> odoo18
cd odoo18
cp .env.example .env
# edit .env  -> isi POSTGRES_PASSWORD
# edit config/odoo.conf -> samakan db_password dengan .env,
#                          ganti admin_passwd
mkdir -p data/postgres data/odoo addons custom_addons
docker compose up -d --build
```

Bila folder di atas dibuat memakai `sudo`, samakan pemiliknya dengan user
Odoo di container (kalau tidak, Odoo error `Permission denied` di
`/var/lib/odoo/sessions`):

```bash
docker compose exec -u 0 odoo chown -R odoo:odoo /var/lib/odoo /mnt/extra-addons /mnt/custom-addons
docker compose restart odoo
```

Odoo bisa dibuka di `http://<ip-server>:8069`.

Folder penting (semua di host, aman dari `docker compose up -d` berulang):

| Folder host        | Isi                                   |
|--------------------|---------------------------------------|
| `data/postgres/`   | File database PostgreSQL              |
| `data/odoo/`       | Filestore & attachment Odoo           |
| `addons/`          | Addons tambahan (extra)               |
| `custom_addons/`   | Modul custom client                   |

## Opsi: data di /mnt/storage

Bila server punya mount storage besar (mis. `/mnt/storage`), dua cara
supaya database & filestore tinggal di sana, bukan di disk sistem:

**Cara 1 — clone langsung di storage (paling sederhana):**

```bash
cd /mnt/storage
sudo git clone <repo-ini> odoo18
cd odoo18
```

Sisa langkahnya sama seperti di atas; semua folder `data/`, `addons/`,
`custom_addons/` otomatis berada di `/mnt/storage/odoo18/`.

**Cara 2 — repo di tempat lain, volume diarahkan manual:**

Edit `docker-compose.yml`, ubah volume menjadi path absolut:

```yaml
    volumes:
      - /mnt/storage/odoo18/data/postgres:/var/lib/postgresql/data
```

dan untuk service `odoo`:

```yaml
    volumes:
      - /mnt/storage/odoo18/data/odoo:/var/lib/odoo
      - ./config:/etc/odoo
      - /mnt/storage/odoo18/addons:/mnt/extra-addons
      - /mnt/storage/odoo18/custom_addons:/mnt/custom-addons
```

Buat dulu foldernya: `sudo mkdir -p /mnt/storage/odoo18/{data/postgres,data/odoo,addons,custom_addons}`.

## Alias shell (opsional)

File `odoo-aliases.sh` berisi alias praktis (`odoo18-restart`, `odoo18-logs`,
`odoo18-db`, `odoo18-shell`, dll.) supaya tidak perlu mengetik perintah
docker compose yang panjang. Tempel isinya ke `~/.zshrc` atau `~/.bashrc`,
sesuaikan path compose pada baris `export ODOO19_COMPOSE=...`, lalu muat
ulang shell-nya (`source ~/.zshrc`).

## Real-time (Discuss/chat/notifikasi)

Notifikasi dan chat Odoo 18 jalan lewat longpolling/WebSocket, dan itu
hanya hidup bila `workers` di `config/odoo.conf` minimal 1 (default
template ini: `workers = 2`, `longpolling_port = 8072`). Dengan
`workers = 0`, browser menampilkan "Real-time connection lost" dan
tanda sudah-dibaca tidak pernah sampai ke layar.

Di belakang nginx, teruskan kedua jalur ini ke port longpolling
(`8073` di `docker-compose.yml` template ini):

```nginx
location /longpolling {
    proxy_pass http://127.0.0.1:8073;
}

location /websocket {
    proxy_pass http://127.0.0.1:8073;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 720s;
}
```

Perhatian bila satu server menjalankan dua Odoo: port HTTP template ini
(`8072:8069`) bertabrakan dengan port longpolling Odoo lain yang memakai
`8072` di host yang sama — pindahkan pemetaan HTTP-nya (mis. `8071:8069`).

## Catatan

- Jangan commit file `.env` asli; repo hanya menyimpan `.env.example`.
- Setelah mengubah `Dockerfile` (mis. tambah library), jalankan
  `docker compose build odoo && docker compose up -d`.
- Untuk di belakang reverse proxy / Cloudflare Tunnel, set
  `proxy_mode = True` di `config/odoo.conf`.
- Odoo 18 butuh modul versi `19.0.x` — modul 18.0 tidak bisa langsung dipasang.
