# 🚀 Railway Deploy - Quick Start

Execute estes comandos **um por vez** no seu terminal:

## 1️⃣ Login (abre navegador)
```bash
railway login
```

## 2️⃣ Inicializar projeto
```bash
railway init
```
→ Escolha: "Create a new project"
→ Nome: **cronos-poc**

## 3️⃣ Adicionar PostgreSQL
**No navegador:**
1. Vá em: https://railway.app/dashboard
2. Abra o projeto **cronos-poc**
3. Click **New** → **Database** → **Add PostgreSQL**
4. ✅ Aguarde ~60 segundos até o status ficar "Active"

## 4️⃣ Configurar variáveis (COPIE E COLE TUDO DE UMA VEZ)
```bash
railway variables set \
  RAILS_MASTER_KEY="$(cat config/master.key)" \
  ADMIN_EMAIL="igor@cronos-poc.com" \
  ADMIN_PASSWORD="Cronos2025!" \
  RAILS_ENV="production" \
  RAILS_SERVE_STATIC_FILES="true" \
  RAILS_LOG_TO_STDOUT="true" \
  RAILS_MAX_THREADS="5"
```

⚠️ **IMPORTANTE:** Mude `ADMIN_PASSWORD` para uma senha segura!

## 5️⃣ Commit arquivos
```bash
git add Procfile railway.json RAILWAY_DEPLOY.md DEPLOY_QUICK_START.md scripts/
git commit -m "feat: Add Railway deployment configuration"
```

## 6️⃣ DEPLOY! 🚀
```bash
railway up
```

## 7️⃣ Monitorar deploy
```bash
railway logs --follow
```
(Ctrl+C para sair dos logs)

## 8️⃣ Abrir aplicação
```bash
railway open
```

---

## ✅ Checklist Pré-Deploy

- [ ] Executou `railway login`
- [ ] Criou projeto no Railway
- [ ] PostgreSQL adicionado e **Active**
- [ ] Variáveis de ambiente configuradas
- [ ] Executou `railway up`
- [ ] Logs mostram deploy bem-sucedido
- [ ] App aberto no navegador com `railway open`

---

## 🔐 Credenciais de Login (após deploy)

**Email:** igor@cronos-poc.com
**Senha:** [a que você definiu em ADMIN_PASSWORD]

---

## 📊 Comandos Úteis

```bash
# Ver status do projeto
railway status

# Ver todas as variáveis
railway variables

# Executar comando no servidor
railway run rails console

# Ver logs em tempo real
railway logs --follow

# Redeployer
railway up --detach
```

---

## ⚠️ Troubleshooting

### Erro de Database
```bash
railway variables | grep DATABASE_URL
# Se vazio, PostgreSQL não foi provisionado corretamente
```

### Deploy falhou
```bash
railway logs
# Veja os erros nos logs
```

### Mudar variável
```bash
railway variables set ADMIN_PASSWORD="nova_senha_aqui"
railway up  # Redeployer
```
