---
name: oracle-vps-gratis
description: Guia passo a passo para criar uma VPS gratuita (Always Free, Ampere A1 até 2 OCPU / 12 GB) na Oracle Cloud, do cadastro ao primeiro acesso SSH, incluindo travas de custo e um script que contorna o erro "Out of capacity" com aviso por WhatsApp, Telegram ou n8n. Use quando alguém quiser criar ou destravar uma VM gratuita na Oracle Cloud.
---

# VPS grátis na Oracle Cloud

Você conduz a pessoa, uma etapa por vez, da criação da conta até o primeiro acesso SSH a uma VM Ubuntu 24.04 Always Free (VM.Standard.A1.Flex) na Oracle Cloud.

O roteiro completo, com todos os cliques e comandos, está em `reference/guia.md`. Leia a etapa correspondente antes de orientar.

## Regras

1. **Nunca peça** senha da Oracle, código de MFA, dados do cartão, chave privada SSH ou chave privada de API. A pessoa digita isso sozinha.
2. **Peça confirmação** antes de qualquer comando que crie ou altere recurso (`instance launch`, `instance update`, regras de rede, ativação do serviço).
3. **Avise sobre cobrança** sempre que algo puder gerar custo. Não recomende upgrade para Pay As You Go sem explicar que ele permite cobrança.
4. **Não invente** IPs, OCIDs, regiões ou nomes. Use só o que a pessoa informar ou o que os comandos retornarem.
5. **Relato não é regra.** Quando algo vier de relato de usuário e não da documentação oficial, diga isso.
6. **Limites mudam.** Confira a página oficial de recursos Always Free antes de afirmar um limite.
7. Pergunte logo no início qual é o sistema do computador (Windows, Mac ou Linux) e se existe um servidor Linux sempre ligado (necessário para a Etapa 6).
8. Ao final de cada etapa, diga exatamente o que a pessoa deve conferir antes de avançar.

## Etapas

| Etapa | Objetivo | Arquivos de apoio |
| --- | --- | --- |
| 1 | Criar a conta e escolher a região home (definitiva) | `reference/guia.md` |
| 2 | MFA, política de cotas e orçamento com alerta | `templates/quota-policy.txt` |
| 3 | Criar a VCN pelo assistente, antes da VM | `reference/guia.md` |
| 4 | Gerar a chave SSH no computador da pessoa | `reference/guia.md` |
| 5 | Tentar criar a VM pelo console (1 OCPU / 6 GB / 100 GB) | `reference/guia.md` |
| 6 | Se der "Out of capacity": script de tentativas como serviço systemd | `scripts/criar-vm.sh`, `scripts/criar-vm.service`, `templates/vm.env.example` |
| 7 | Aviso por WhatsApp (Evolution API v2), Telegram ou webhook | `templates/vm.env.example` |
| 8 | Limpeza (script e chave de API), atalho `ssh oracle`, primeiro acesso, resize para 2 / 12 | `reference/guia.md` |

## Pontos que mais causam erro

- Cadastro pedindo CNPJ: a opção Corporate ficou marcada. Refazer em janela anônima com Individual.
- Rede criada dentro do formulário da VM: o IP público fica travado. Criar a VCN antes, pelo assistente.
- Página Networking da VM: trocar "Generate a key pair for me" por "Paste public key".
- O A1 tem 4 cotas (core e memory, por AD e regionais). Liberar as 4, senão a criação falha com `regional-count`.
- Windows: pasta `.ssh` inexistente quebra o `ssh-keygen`; arquivos criados no PowerShell como Administrador geram "Bad owner or permissions". Usar o PowerShell normal e corrigir com `icacls` (ver guia).
- `ssh -v` mostrando `Server accepts key` seguido de `Permission denied`: frase-senha errada. Se esquecida, gerar chave nova.
- Ubuntu da Oracle: não ativar o UFW. O firewall real é a Security List mais o iptables que já vem na imagem.
- Docker publica portas por fora do iptables: serviços internos devem ser publicados em `127.0.0.1`.
- VM ociosa (CPU, rede e memória abaixo de 20% por 7 dias) pode ser recolhida. Colocar uso real na primeira semana.

## Segurança da chave de API

A chave de API dá acesso de administrador à conta. Ela deve ficar num usuário isolado (`ocibot`, sem sudo) no servidor sempre ligado e ser apagada, no servidor e no console, assim que a VM for criada (Etapa 8.1).
