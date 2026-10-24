# VPS grátis na Oracle Cloud (skill para o Claude)

Passo a passo completo para criar uma VPS **Always Free** na Oracle Cloud (Ubuntu 24.04, Ampere A1, até 2 CPUs e 12 GB de RAM), do cadastro ao primeiro acesso SSH, sem pagar nada.

Inclui a solução para o erro mais comum, **"Out of capacity"**: um script que tenta criar a VM sozinho e **avisa no WhatsApp, Telegram ou n8n** quando consegue.

## O que tem aqui

| Arquivo | Para que serve |
| --- | --- |
| `SKILL.md` | Instruções para o Claude conduzir você etapa por etapa |
| `reference/guia.md` | O guia completo, para ler sem o Claude |
| `templates/quota-policy.txt` | Política de cotas que bloqueia qualquer recurso pago |
| `templates/vm.env.example` | Configuração do script e dos avisos |
| `scripts/criar-vm.sh` | Script que tenta criar a VM até haver vaga |
| `scripts/criar-vm.service` | Serviço systemd para o script rodar 24 horas |

## Como usar

**Só o guia:** abra [`reference/guia.md`](reference/guia.md) e siga as 8 etapas.

**Como skill no Claude Code:**

```bash
git clone https://github.com/NoronhaLab/oracle-vps-gratis ~/.claude/skills/oracle-vps-gratis
```

Depois peça ao Claude: *"Quero criar minha VPS grátis na Oracle"*.

**Como skill no Claude (app ou web):** baixe o repositório em **Code > Download ZIP** e envie o arquivo na área de Skills das configurações do Claude.

## As 8 etapas

1. Criar a conta e escolher a região home (definitiva)
2. MFA e travas de custo (cotas e orçamento)
3. Criar a rede (VCN) antes da VM
4. Gerar a chave SSH
5. Tentar criar a VM pelo console
6. Se der "Out of capacity", script tentando sozinho num servidor sempre ligado
7. Aviso no WhatsApp (Evolution API), Telegram ou webhook do n8n
8. Limpeza da chave de API, primeiro acesso e aumento para 2 CPUs / 12 GB

## Avisos

- Os limites gratuitos mudam. Confira a [página oficial de recursos Always Free](https://docs.oracle.com/pt-br/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm).
- A Oracle permite uma conta gratuita por pessoa.
- A chave de API dá acesso total à sua conta. Use um usuário isolado e apague a chave assim que a VM for criada.
- Nunca publique seus arquivos `vm.env`, `config` ou chaves privadas.
- Este material não tem relação oficial com a Oracle. Use por sua conta e risco.

## Créditos

Baseado em uma configuração real feita em outubro de 2026 e em um roteiro compartilhado por outro usuário, que originou a política de cotas e a primeira versão do script. Esta versão adiciona avisos por WhatsApp, Telegram e webhook, modo de teste, limite de tempo por chamada e a seção de erros comuns.
