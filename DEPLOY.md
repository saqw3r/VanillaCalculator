# Deploy Calculator to Raspberry Pi

Two options: **containerized (k3s)** or **direct** (no containerization).

## Prerequisites (both options)

- Raspberry Pi 4/5 running Raspberry Pi OS (64-bit)
- Domain pointing to Cloudflare (e.g. `calculator.example.com`)
- Cloudflare Tunnel (`cloudflared`) installed on the Pi
- SSH access to the Pi

---

## Option 1: Containerized (k3s)

### 1. Install k3s

```bash
curl -sfL https://get.k3s.io | sh -
sudo k3s kubectl get nodes   # verify
```

### 2. Build & import images

On the Pi (or build elsewhere and `scp` the tarball):

```bash
cd /path/to/VanillaCalculator

# --- Frontend ---
npm install
npx next build --no-lint
podman build -t calculator-frontend:arm64 -f Dockerfile.frontend .
podman save calculator-frontend:arm64 | sudo k3s ctr images import -

# --- API ---
podman build -t calculator-api:arm64 backend/CalculatorApi/
podman save calculator-api:arm64 | sudo k3s ctr images import -
```

### 3. Deploy

```bash
sudo k3s kubectl apply -k k8s/
sudo k3s kubectl get pods -n calculator   # verify all 3 pods are Running
```

### 4. Cloudflare Tunnel config

`~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /home/pi/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: calculator.example.com
    path: /api/*
    service: http://localhost:30080
  - hostname: calculator.example.com
    service: http://localhost:30081
  - service: http_status:404
```

Restart tunnel:

```bash
sudo systemctl restart cloudflared
```

---

## Option 2: Direct (no containers)

Frontend static files are served by the C# API itself — one port, one process, no k8s.

### 1. Install dependencies

```bash
sudo apt update && sudo apt install -y postgresql postgresql-client dotnet-sdk-10.0 nodejs npm
```

### 2. Set up PostgreSQL

```bash
sudo -u postgres psql -c "CREATE USER calculator WITH PASSWORD 'calculator_pass';"
sudo -u postgres psql -c "CREATE DATABASE calculator OWNER calculator;"
```

### 3. Build frontend

```bash
cd /path/to/VanillaCalculator
npm install
npx next build --no-lint
```

### 4. Copy static files into API project

```bash
rm -rf backend/CalculatorApi/wwwroot
cp -r out backend/CalculatorApi/wwwroot
```

### 5. Build & run the API

```bash
cd backend/CalculatorApi
export ConnectionStrings__Default="Host=localhost;Port=5432;Database=calculator;Username=calculator;Password=calculator_pass"
dotnet run --urls "http://0.0.0.0:8080"
```

Or publish and run as a systemd service:

```bash
dotnet publish -c Release -o /opt/calculator-api
```

Create `/etc/systemd/system/calculator-api.service`:

```ini
[Unit]
Description=Calculator API
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/calculator-api
ExecStart=/opt/calculator-api/CalculatorApi
Restart=always
RestartSec=5
Environment=ConnectionStrings__Default=Host=localhost;Port=5432;Database=calculator;Username=calculator;Password=calculator_pass

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now calculator-api
```

### 6. Cloudflare Tunnel config

Single port serves everything:

`~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /home/pi/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: calculator.example.com
    service: http://localhost:8080
  - service: http_status:404
```

Restart tunnel:

```bash
sudo systemctl restart cloudflared
```

---

## Verify

Open `https://calculator.example.com` in a browser. Try `2 + 3 =` — the result should appear.

API health check:

```bash
curl https://calculator.example.com/api/history
```
