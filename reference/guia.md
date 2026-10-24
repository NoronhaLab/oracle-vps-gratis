# VPS grátis na Oracle Cloud: guia completo

No final você terá um servidor Ubuntu 24.04 na Oracle Cloud com até **2 CPUs ARM e 12 GB de RAM**, sem pagar nada, acessível por SSH com chave e protegido contra cobranças acidentais.

| Item | Valor |
| --- | --- |
| Custo mensal | R$ 0 (recursos Always Free) |
| Máquina | Ampere A1 (ARM), até 2 OCPUs e 12 GB de RAM |
| Disco | até 200 GB no total |
| Tráfego de saída | 10 TB por mês |
| Tempo de configuração | cerca de 1 hora |
| Tempo até a VM nascer | de minutos a alguns dias, conforme a vaga na região |

Os limites mudam. Confira a [página oficial de recursos Always Free](https://docs.oracle.com/pt-br/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).

## Antes de começar

| Item | Por que | Atenção |
| --- | --- | --- |
| Cartão de **crédito** no seu nome | Verificação de identidade (cobrança pequena e estornada) | Virtual, pré-pago e débito costumam ser recusados |
| Celular com SMS | Código de verificação | Precisa receber SMS na hora |
| E-mail que você lê | Toda comunicação da conta | Aviso de conta pronta chega aqui |
| App autenticador | MFA | Oracle Mobile Authenticator ou Google Authenticator |
| Gerenciador de senhas | Senha da conta e frase-senha das chaves | Bitwarden, 1Password ou o do Google |
| Computador com terminal | Chave SSH e acesso | Windows (PowerShell), Mac ou Linux |
| Servidor sempre ligado (opcional) | Rodar o script da Etapa 6 | VPS que você já tenha, Raspberry Pi ou PC que não desliga |

A Oracle permite **uma conta gratuita por pessoa**. Não crie contas extras para trocar de região.

## Etapa 1: Criar a conta

1. Acesse **oracle.com/br/cloud/free** > **Comece gratuitamente**
2. País, nome e e-mail. Confirme pelo link do e-mail
3. Crie a senha e salve no gerenciador de senhas
4. **Customer type**: **Individual** (CPF e cartão pessoal) ou **Corporate** (só com CNPJ ativo, formato 12345678/0001-18)
5. **Cloud Account Name**: anote, é pedido em todo login e não muda
6. **Home Region**: definitiva. Os servidores gratuitos só podem ser criados nela. No Brasil: Brazil East (Sao Paulo) ou Brazil Southeast (Vinhedo)
7. Endereço **com número**, igual ao do cartão
8. SMS, cartão, contrato e **Iniciar minha avaliação gratuita**
9. Aguarde o e-mail **"Your Oracle Cloud Account is Fully Provisioned"**

Pegadinhas:

- Pediu CNPJ sem você ter: Corporate ficou marcado. Janela anônima, refaça com Individual e confira que o campo da empresa sumiu
- O escudo do Brave pode travar a tela de pagamento. Use o Chrome
- Ignore o botão **Upgrade**. O Free Trial dá 30 dias de créditos e depois continua com os recursos Always Free, sem cobrança

## Etapa 2: MFA e travas de custo

A **política de cotas** impede a criação de algo pago. O orçamento só avisa.

### 2.1 Login e MFA

1. **cloud.oracle.com**, Cloud Account Name, e-mail e senha
2. Configure o MFA no app autenticador
3. Confira se a região no topo é a sua Home Region

### 2.2 Política de cotas

1. **☰ > Governance & Administration > Tenancy Management > Quota Policies**, compartment **(root)**
2. **Create Quota Policy**: nome `TRAVA-ALWAYS-FREE`, descrição `Bloqueia recursos pagos`
3. Cole o conteúdo de `templates/quota-policy.txt` e clique em **Create**

| Linhas | O que fazem |
| --- | --- |
| 1 a 3 | Bloqueiam toda CPU e liberam 2 OCPUs do A1 |
| 4 a 6 | Bloqueiam toda memória e liberam 12 GB do A1 |
| 7 e 8 | Disco até 200 GB e até 5 backups |
| 9 | Bloqueiam balanceadores de carga |
| 10 | Object Storage até 20 GB |

O A1 tem duas cotas de CPU e duas de memória (por AD e regional). Liberar só uma gera o erro `compartment quotas were exceeded ... regional-count`.

### 2.3 Orçamento

1. **☰ > Billing & Cost Management > Budgets > Create Budget**
2. Nome `alerta-qualquer-gasto`, descrição `Alerta para qualquer gasto fora do Always Free`
3. Compartment raiz, Monthly, valor `1`
4. Alerta: Actual Spend, Percentage of Budget, threshold `1`, seu e-mail

## Etapa 3: Criar a rede (VCN)

Crie a rede **antes** da VM. Criar dentro do formulário da VM costuma travar o IP público.

1. **☰ > Networking > Virtual Cloud Networks**, compartment raiz
2. **Actions > Start VCN Wizard** > **Create VCN with Internet Connectivity**
3. Nome `vcn-principal`, demais campos no padrão
4. **Next > Create**

Cria sub-rede pública e privada, Internet Gateway, rotas e uma Security List com só a porta 22. Sem custo.

## Etapa 4: Gerar a chave SSH

Antes de gerar, crie no gerenciador de senhas a entrada "Chave SSH Oracle" e guarde a frase-senha nela. Frase esquecida não tem recuperação.

### Windows (PowerShell normal, sem "Executar como administrador")

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh"
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\oracle_vps" -C "oracle-vps"
Get-Content "$env:USERPROFILE\.ssh\oracle_vps.pub"
```

### Mac ou Linux

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/oracle_vps -C "oracle-vps"
cat ~/.ssh/oracle_vps.pub
```

A linha `ssh-ed25519 ...` é pública. O arquivo sem `.pub` é privado e nunca sai do seu computador.

## Etapa 5: Criar a VM pelo console

**☰ > Compute > Instances > Create instance**. Comece com 1 OCPU e 6 GB (mais vaga) e aumente depois.

| Página | O que preencher |
| --- | --- |
| 1. Basic information | Nome `vps-principal`. Change shape: Virtual machine > Ampere > **VM.Standard.A1.Flex**, 1 OCPU, 6 GB. Change image: **Canonical Ubuntu 24.04** (não a Minimal) |
| 2. Security | Padrão |
| 3. Networking | Select existing VCN `vcn-principal`, select existing subnet **public**, marcar **Automatically assign public IPv4 address**, IPv6 desmarcado. Add SSH keys: **Paste public key** |
| 4. Storage | **Specify a custom boot volume size**: `100` GB, VPU 10. Sem block volumes |
| 5. Review | Conferir e **Create** |

Se aparecer "Download private key" na página 3, a opção "Generate a key pair for me" está marcada. Troque para Paste public key.

Erro mais comum:

```
Out of capacity for shape VM.Standard.A1.Flex in availability domain AD-1.
```

Falta de máquina ARM livre na região. Vá para a Etapa 6. Não faça upgrade para Pay As You Go só por isso: a prioridade é relato de usuário, não regra oficial, e a conta passa a permitir cobrança.

## Etapa 6: Script que tenta sozinho

Precisa de um servidor Linux sempre ligado. Em São Paulo, um relato de outubro de 2026 levou cerca de 12 horas; há relatos de dias.

A chave de API dá acesso de administrador à conta. Ela fica num usuário isolado, sem sudo, e é apagada quando a VM nascer. As cotas da Etapa 2 continuam valendo pela API.

Se o servidor já roda algo importante, cada chamada da CLI ocupa 100 a 200 MB de RAM por alguns segundos. Confira com `free -h`.

### 6.1 Usuário isolado e CLI

Como root:

```bash
useradd -m -s /bin/bash ocibot
su - ocibot
```

Como `ocibot`:

```bash
mkdir -p ~/.oci && chmod 700 ~/.oci
python3 -m venv ~/.oci/venv && ~/.oci/venv/bin/pip install --quiet --upgrade pip oci-cli
~/.oci/venv/bin/oci --version
```

Ubuntu/Debian: se o venv falhar, rode antes como root `apt install -y python3-venv`.

### 6.2 Chave de API

```bash
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
chmod 600 ~/.oci/oci_api_key.pem
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
echo "OCI_API_KEY" >> ~/.oci/oci_api_key.pem
cat ~/.oci/oci_api_key_public.pem
```

No console: **Avatar > My profile > Tokens and keys > Add API key > Paste a public key**, cole de `BEGIN` a `END`, **Add**, copie o **Configuration file preview**.

```bash
cat > ~/.oci/config <<'EOF'
[DEFAULT]
user=COLE_AQUI
fingerprint=COLE_AQUI
tenancy=COLE_AQUI
region=COLE_AQUI
key_file=/home/ocibot/.oci/oci_api_key.pem
EOF
chmod 600 ~/.oci/config
~/.oci/venv/bin/oci iam region-subscription list --output table
```

Deve mostrar sua região com `is-home-region` = `True`.

### 6.3 Coletar os IDs

```bash
OCI=~/.oci/venv/bin/oci
T=$(grep ^tenancy ~/.oci/config | cut -d= -f2)
$OCI iam availability-domain list -c $T --query 'data[].name' --raw-output
$OCI network subnet list -c $T --query 'data[].{nome:"display-name",id:id,sem_ip_publico:"prohibit-public-ip-on-vnic"}' --output table
$OCI compute image list -c $T --operating-system "Canonical Ubuntu" --operating-system-version "24.04" --shape VM.Standard.A1.Flex --sort-by TIMECREATED --sort-order DESC --limit 1 --query 'data[0].{nome:"display-name",id:id}' --output table
```

Use a sub-rede com `sem_ip_publico` = `False` e a imagem terminada em `aarch64`.

### 6.4 Configuração da VM

Copie `templates/vm.env.example` para `~/.oci/vm.env`, preencha os IDs e rode:

```bash
chmod 600 ~/.oci/vm.env
echo "COLE_AQUI_SUA_CHAVE_ssh-ed25519" > ~/.oci/vm_authorized_keys
```

### 6.5 O script

Copie `scripts/criar-vm.sh` para `~/.oci/criar-vm.sh` e rode:

```bash
chmod 700 ~/.oci/criar-vm.sh && bash -n ~/.oci/criar-vm.sh && echo SCRIPT_OK
```

| Situação | O que o script faz |
| --- | --- |
| Sem vaga | Espera 2,5 a 3 minutos e tenta de novo |
| Excesso de requisições | Espera 4 vezes mais |
| Erro temporário ou sem resposta | Tenta de novo |
| VM criada ou já existente | Grava o ID, avisa e para |
| Outro erro (cota, permissão, configuração) | Grava o motivo, avisa e para |

### 6.6 Rodar como serviço

Como root, copie `scripts/criar-vm.service` para `/etc/systemd/system/criar-vm.service` e rode:

```bash
systemctl daemon-reload && systemctl enable --now criar-vm
sleep 60; systemctl status criar-vm --no-pager | head -5; cat /home/ocibot/.oci/criar-vm.log
```

Esperado: `active (running)` e `tentativa 1: sem vaga`. Para desligar: `systemctl stop criar-vm`.

## Etapa 7: Aviso no WhatsApp, Telegram ou n8n

O script avisa no teste, quando a VM é criada e quando para por erro. Preencha no `~/.oci/vm.env` as variáveis do canal (veja `templates/vm.env.example`).

| Canal | Quando usar | O que precisa |
| --- | --- | --- |
| WhatsApp (Evolution API v2) | Já tem uma instância conectada a um número | URL, instância, API key, número de destino com DDI e DDD |
| Telegram | Gratuito e rápido | Token do bot (@BotFather) e chat id |
| Webhook (n8n, Make) | Já tem automações | URL que aceite POST `{"mensagem": "..."}` |

Na Evolution API v1 o corpo da requisição é diferente; nesse caso use o webhook do n8n.

Testar como `ocibot`:

```bash
bash ~/.oci/criar-vm.sh --testar-aviso && tail -3 ~/.oci/criar-vm.log
```

O script só lê o `vm.env` ao iniciar. Depois de editar, como root: `systemctl restart criar-vm`.

## Etapa 8: Quando a VM nascer

### 8.1 Desligar o script e apagar a chave de API

Como root no servidor sempre ligado:

```bash
cat /home/ocibot/.oci/criar-vm.feito
systemctl disable --now criar-vm
rm /etc/systemd/system/criar-vm.service && systemctl daemon-reload
userdel -r ocibot && echo LIMPEZA_OK
```

No console: **Avatar > My profile > Tokens and keys**, menu da chave de API > **Delete**.

### 8.2 Atalho no seu computador

IP em **☰ > Compute > Instances > vps-principal > Public IPv4 address**.

Windows:

```powershell
@"
Host oracle
    HostName IP_DA_VM
    User ubuntu
    IdentityFile ~/.ssh/oracle_vps
    IdentitiesOnly yes
"@ | Out-File -Encoding ascii -Append "$env:USERPROFILE\.ssh\config"
```

Mac/Linux: adicione o mesmo bloco (sem `@"` e `"@ | ...`) a `~/.ssh/config`.

### 8.3 Primeiro acesso

```bash
ssh oracle
uname -m; nproc; free -h; df -h /
```

Esperado: `aarch64`, 1 CPU, cerca de 6 GB de RAM e 100 GB de disco.

### 8.4 Aumentar para 2 OCPUs e 12 GB

Console: **vps-principal > Actions > Edit > Edit shape**, 2 OCPUs e 12 GB. A VM reinicia e mantém IP e disco. Se der "Out of capacity", fique com 1 / 6 e tente outro dia.

A Oracle pode recolher VMs com CPU, rede e memória abaixo de 20% por 7 dias. Coloque uso real na primeira semana e acompanhe em **Instance > Metrics**.

## Erros comuns

| Erro ou sintoma | Causa | Solução |
| --- | --- | --- |
| Cadastro pede CNPJ | Corporate marcado | Janela anônima e Individual |
| `Saving key ... No such file or directory` | Pasta `.ssh` não existe | `New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh"` |
| "Download private key" na criação da VM | "Generate a key pair for me" marcado | Paste public key |
| `Out of capacity` | Sem vaga na região | Etapa 6 |
| `Bad owner or permissions on ...\.ssh\config` | Arquivo criado como Administrador | `icacls` abaixo e PowerShell normal |
| `Permission denied` com `Server accepts key` | Frase-senha errada | Copiar do gerenciador; se esquecida, chave nova |
| `Connection closed` antes da frase-senha | Demora para digitar | Tentar de novo e digitar em até 1 minuto |
| Aviso `append an extra line with 'OCI_API_KEY'` | Recomendação da CLI | `echo "OCI_API_KEY" >> ~/.oci/oci_api_key.pem` |
| `compartment quotas were exceeded ... regional-count` | Só cotas por AD liberadas | Liberar as 4 cotas do A1 |

Correção de permissões no Windows:

```powershell
$u = "$env:USERDOMAIN\$env:USERNAME"
$arquivos = "config","oracle_vps" | ForEach-Object { "$env:USERPROFILE\.ssh\$_" }
foreach ($f in $arquivos) { icacls $f /setowner $u; icacls $f /inheritance:r; icacls $f /grant:r "${u}:F" "*S-1-5-18:F" }
```

Diagnóstico de SSH:

```powershell
ssh -v -o PasswordAuthentication=no oracle 2>&1 | Select-String "Offering|accepts|denied|permissions|passphrase"
```

## Próximos passos

Segurança (SSH só por chave, fail2ban, portas 80 e 443 na Security List), Docker, Caddy com HTTPS e backups. Na imagem Ubuntu da Oracle, **não** ative o UFW: o firewall que vale é a Security List mais o iptables que já vem configurado. O Docker publica portas por fora do iptables, então serviços internos devem ficar em `127.0.0.1`.

## Fontes

- [Recursos Always Free da Oracle Cloud](https://docs.oracle.com/pt-br/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Oracle Cloud Free Tier](https://docs.oracle.com/iaas/Content/FreeTier/freetier.htm)
- [Chaves de API e assinatura de requisições](https://docs.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm)
