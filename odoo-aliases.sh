# ===== Alias Docker Odoo 18 =====
# Tempel isi file ini ke ~/.zshrc atau ~/.bashrc, sesuaikan path
# docker-compose.yml di baris export, lalu jalankan: source ~/.zshrc
# (atau buka terminal baru).

export ODOO19_COMPOSE="/mnt/storage/odoo18/docker-compose.yml"

alias odoo18-start='docker compose -f $ODOO19_COMPOSE start odoo'
alias odoo18-stop='docker compose -f $ODOO19_COMPOSE stop odoo'
alias odoo18-restart='docker compose -f $ODOO19_COMPOSE restart odoo'
alias odoo18-status='docker compose -f $ODOO19_COMPOSE ps'
alias odoo18-logs='docker compose -f $ODOO19_COMPOSE logs --tail=100 odoo'
alias odoo18-logsf='docker compose -f $ODOO19_COMPOSE logs -f odoo'
alias odoo18-up='docker compose -f $ODOO19_COMPOSE up -d'
alias odoo18-down='docker compose -f $ODOO19_COMPOSE down'
alias odoo18-rebuild='docker compose -f $ODOO19_COMPOSE up -d --build'

# User psql di bawah mengikuti POSTGRES_USER di .env (default odoo18).
alias odoo18-db='docker exec -it odoo18-db psql -U odoo18 -d postgres'
alias odoo18-shell='docker exec -it odoo18 bash'
