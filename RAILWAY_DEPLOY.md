# Deploy Cronos POC para Railway

## Pré-requisitos

✅ Railway CLI instalado (`railway` command available)
✅ Conta Railway criada (https://railway.app)
✅ Git repository configurado

## Variáveis de Ambiente Necessárias no Railway

### 1. Rails
```
RAILS_ENV=production
RAILS_MASTER_KEY=<conteúdo do config/master.key>
SECRET_KEY_BASE=<gerado automaticamente ou manual>
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### 2. Database (PostgreSQL)
Railway provisiona automaticamente, mas você pode configurar:
```
DATABASE_URL=<fornecido automaticamente pelo Railway PostgreSQL>
```

Ou manualmente:
```
DATABASE_HOST=<host do postgres>
DATABASE_USERNAME=<user>
DATABASE_PASSWORD=<password>
DATABASE_NAME=cronos_poc_production
```

### 3. Admin User (Single-User System)
```
ADMIN_EMAIL=seu-email@example.com
ADMIN_PASSWORD=senha-segura-aqui
```

### 4. Outras (opcionais)
```
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
```

## Passos para Deploy

### 1. Login no Railway
```bash
railway login
```

### 2. Criar novo projeto
```bash
railway init
```

Ou linkar projeto existente:
```bash
railway link
```

### 3. Adicionar PostgreSQL
No Railway dashboard:
- Go to your project
- Click "New" → "Database" → "Add PostgreSQL"
- Railway auto-configura DATABASE_URL

### 4. Configurar variáveis de ambiente
```bash
# RAILS_MASTER_KEY (conteúdo do config/master.key)
railway variables set RAILS_MASTER_KEY="<cole aqui o conteúdo do master.key>"

# Admin credentials
railway variables set ADMIN_EMAIL="seu@email.com"
railway variables set ADMIN_PASSWORD="senha-forte-123"

# Rails env
railway variables set RAILS_ENV="production"
railway variables set RAILS_SERVE_STATIC_FILES="true"
railway variables set RAILS_LOG_TO_STDOUT="true"
```

### 5. Deploy
```bash
railway up
```

Ou via Git (recomendado):
```bash
git add .
git commit -m "Configure Railway deployment"
git push
railway up --detach
```

### 6. Verificar logs
```bash
railway logs
```

### 7. Abrir aplicação
```bash
railway open
```

## Troubleshooting

### Erro de Database
Se database não conectar:
```bash
railway variables
# Verificar se DATABASE_URL está setada
```

### Erro de Assets
Se assets não carregarem:
```bash
railway run rails assets:precompile
```

### Erro de Migration
```bash
railway run rails db:migrate
railway run rails db:seed
```

### Ver todas as variáveis
```bash
railway variables
```

## Comandos Úteis

```bash
# Ver status do deploy
railway status

# Executar comando no ambiente Railway
railway run rails console

# Ver logs em tempo real
railway logs --follow

# Abrir dashboard do projeto
railway open
```

## Checklist Pré-Deploy

- [ ] config/master.key existe e está no .gitignore
- [ ] Procfile criado
- [ ] railway.json criado (opcional)
- [ ] .env não está commitado
- [ ] Todas as gems de produção estão no Gemfile
- [ ] DATABASE_URL será provisionado pelo Railway PostgreSQL
- [ ] ADMIN_EMAIL e ADMIN_PASSWORD configurados

## Pós-Deploy

1. Acesse a URL fornecida pelo Railway
2. Faça login com ADMIN_EMAIL/ADMIN_PASSWORD
3. Verifique que o sistema está funcional
