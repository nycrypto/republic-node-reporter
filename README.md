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
