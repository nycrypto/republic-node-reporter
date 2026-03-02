# republic-node-reporter (generic)

Bu repo, Cosmos/Tendermint/CometBFT tabanlı bir node’un durumunu **okuyup raporlayan** basit bir bash script içerir.

✅ Read-only: Cüzdan/anahtar/mnemonic istemez.  
✅ Tx göndermez.  
✅ Sadece RPC ve (opsiyonel) log okuyup rapor üretir.

---

## Neler raporlar?
- Güncel **block height**
- **Sync durumu** (`catching_up`)
- **Peer sayısı**
- Validator için temel sinyal: **voting_power**
- (Opsiyonel) Validator detayları: bonded/jailed/commission/tokens
- (Opsiyonel) Log taraması: panic/fatal gibi kritik satırları arar

---

## Gereksinimler
- bash
- curl
- jq

Ubuntu/Debian:

    sudo apt update
    sudo apt install -y curl jq

---

## Çalıştırma (en basit)

    bash scripts/node_report.sh

Varsayılan RPC:
- http://127.0.0.1:26657

Eğer node RPC’n farklıysa aşağıdaki gibi ver:

    NODE_RPC_URL="http://127.0.0.1:26657" bash scripts/node_report.sh

---

## Kullanıcının kendi değerlerini gireceği yerler (ÖNEMLİ)

### 1) RPC adresi (çoğu kullanıcı için gerekli)
- `NODE_RPC_URL` değişkenine kendi RPC adresini yaz.

### 2) Log taraması (opsiyonel)
Systemd ile log taraması istersen:
- `NODE_SERVICE` değişkenine kendi servis adını yaz.

Örnek:

    NODE_SERVICE="mychaind" bash scripts/node_report.sh

### 3) Validator detayları (opsiyonel)
Daha fazla validator bilgisi istersen iki değer girmen gerekir:
- `NODE_BIN` → chain binary (ör: republicd, chaind vs.)
- `NODE_VALOPER` → kendi valoper adresin

Örnek:

    NODE_BIN="republicd" NODE_VALOPER="valoper1xxxxxxxxxxxxxxxxxxxxxx" bash scripts/node_report.sh

---

## Güvenlik
Repo’ya asla şunları koyma:
- Mnemonic / seed phrase
- Private key (*.key, *.pem)
- Keyring klasörleri
- .env
- Node data/db klasörleri
- SSH key’leri

---

## (Opsiyonel) Telegram’a otomatik bildirim (00:00)

Bu bölüm, raporu gece 00:00’da otomatik çalıştırıp Telegram’a mesaj olarak göndermek isteyenler içindir.

### Telegram Bot Token ve Chat ID nedir?
- **BOT_TOKEN**: Telegram’da oluşturduğun botun gizli anahtarıdır. Paylaşma, GitHub’a koyma.
- **CHAT_ID**: Mesajın gideceği sohbetin (DM veya grup) kimliğidir.

> Bu iki bilgiyi **asla repoya yazma**. Sadece sunucunda `.env` dosyasında tut.

### 1) Telegram bot oluştur (BOT_TOKEN alma)
1. Telegram’da **@BotFather**’ı aç.
2. `/newbot` yaz.
3. Bot ismi ver (ör: `MyNodeReporterBot`)
4. Kullanıcı adı ver (sonu `bot` ile bitmeli) (ör: `mynode_reporter_bot`)
5. BotFather sana bir **token** verecek: `123456:ABC...`
   - İşte bu senin **TELEGRAM_BOT_TOKEN**’ın.

### 2) Chat ID bulma (TELEGRAM_CHAT_ID)
**DM (kendine mesaj) için:**
1. BotFather’dan aldığın botu aç ve **/start** gönder.
2. Tarayıcıdan şunu aç (TOKEN’ı kendi tokenınla değiştir):
   `https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getUpdates`
3. Açılan JSON içinde `"chat":{"id": ... }` kısmındaki sayı senin **CHAT_ID**’indir.

**Grup için:**
1. Botu gruba ekle.
2. Grupta bota bir mesaj at veya `/start` yaz.
3. Aynı `getUpdates` linkinde bu sefer chat id genelde `-100...` gibi negatif/büyük sayı çıkar.
   - O da grup **CHAT_ID**’dir.

### 3) Sunucuda `.env` oluştur (gizli kalacak)
Repo klasöründe `.env` dosyasına şunları yaz:

    TELEGRAM_BOT_TOKEN=BURAYA_TOKEN
    TELEGRAM_CHAT_ID=BURAYA_CHAT_ID
    NODE_RPC_URL=http://127.0.0.1:26657

> `NODE_RPC_URL` kendi node RPC adresin olmalı.  
> `.env` dosyasını GitHub’a koyma.

### 4) Telegram’a gönderen script (notify wrapper)
Repo içine yeni bir dosya ekle: `scripts/notify_telegram.sh`

İçeriği:

    #!/usr/bin/env bash
    set -euo pipefail

    # Load variables from .env if present
    if [ -f .env ]; then
      set -a
      . ./.env
      set +a
    fi

    : "${TELEGRAM_BOT_TOKEN:?Missing TELEGRAM_BOT_TOKEN}"
    : "${TELEGRAM_CHAT_ID:?Missing TELEGRAM_CHAT_ID}"

    REPORT="$(bash scripts/node_report.sh 2>&1)"

    curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${REPORT}"

Sonra çalıştırılabilir yap:

    chmod +x scripts/notify_telegram.sh

### 5) Cron ile her gün 00:00’da Telegram bildirimi
Cron’u aç:

    crontab -e

Şunu ekle:

    0 0 * * * cd /path/to/repo && /bin/bash scripts/notify_telegram.sh >> logs/telegram_notify.log 2>&1

> `/path/to/repo` kısmını repo’nun sunucudaki dizini ile değiştir.  
> `logs/` yoksa oluştur: `mkdir -p logs`

### Güvenlik notu
- Token ve chat id gizlidir. Paylaşma.
- `.env` dosyası repo’ya girerse token sızar; bu yüzden `.gitignore` var.
