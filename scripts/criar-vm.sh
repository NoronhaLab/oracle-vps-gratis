#!/usr/bin/env bash
# Tenta criar a VM Always Free (A1) na Oracle Cloud ate haver vaga e avisa quando conseguir.
# Uso: bash criar-vm.sh               (roda em laco ate criar ou parar)
#      bash criar-vm.sh --testar-aviso (so testa os avisos)
# Configuracao: ~/.oci/vm.env (veja templates/vm.env.example)
set -uo pipefail
export SUPPRESS_LABEL_WARNING=True
D="$HOME/.oci"
OCI="$D/venv/bin/oci"
LOG="$D/criar-vm.log"
FEITO="$D/criar-vm.feito"
PARADO="$D/criar-vm.parado"
source "$D/vm.env"
INTERVALO=${INTERVALO:-150}

log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

avisar() {
  local t=${1//\"/\'}
  log "AVISO: $t"
  if [[ -n ${EVO_URL:-} && -n ${EVO_INSTANCIA:-} && -n ${EVO_APIKEY:-} && -n ${EVO_NUMERO:-} ]]; then
    curl -s -m 20 -X POST "$EVO_URL/message/sendText/$EVO_INSTANCIA" \
      -H "apikey: $EVO_APIKEY" -H "Content-Type: application/json" \
      -d "{\"number\":\"$EVO_NUMERO\",\"text\":\"$t\"}" >/dev/null || log "falha no aviso WhatsApp"
  fi
  if [[ -n ${TELEGRAM_TOKEN:-} && -n ${TELEGRAM_CHAT:-} ]]; then
    curl -s -m 20 "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
      --data-urlencode "chat_id=${TELEGRAM_CHAT}" --data-urlencode "text=${t}" >/dev/null || log "falha no aviso Telegram"
  fi
  if [[ -n ${WEBHOOK_URL:-} ]]; then
    curl -s -m 20 -X POST "$WEBHOOK_URL" -H "Content-Type: application/json" \
      -d "{\"mensagem\":\"$t\"}" >/dev/null || log "falha no aviso webhook"
  fi
}

parar() { echo "$1" > "$PARADO"; avisar "Oracle: parei de tentar criar a $NOME. Motivo: $1"; exit 0; }

if [[ ${1:-} == --testar-aviso ]]; then avisar "Teste: aviso da VM Oracle funcionando"; exit 0; fi
[[ -e $FEITO || -e $PARADO ]] && exit 0

log "Iniciado"
tentativa=0
while true; do
  tentativa=$((tentativa + 1))

  # Protecao contra duplicata: se a VM ja existir, para.
  existente=$(timeout 120 "$OCI" --no-retry compute instance list -c "$COMPARTMENT" --display-name "$NOME" \
    --query "data[?\"lifecycle-state\"!='TERMINATED' && \"lifecycle-state\"!='TERMINATING'] | [0].id" \
    --raw-output 2>>"$LOG")
  if [[ -n $existente && $existente != null ]]; then
    echo "$existente" > "$FEITO"; avisar "Oracle: a VM $NOME ja existe."; exit 0
  fi

  saida=$(timeout 120 "$OCI" --no-retry compute instance launch \
    -c "$COMPARTMENT" --availability-domain "$AD" --display-name "$NOME" \
    --shape VM.Standard.A1.Flex --shape-config "{\"ocpus\": $OCPUS, \"memoryInGBs\": $MEMORIA}" \
    --image-id "$IMAGE" --subnet-id "$SUBNET" --assign-public-ip true \
    --boot-volume-size-in-gbs "$DISCO" --is-pv-encryption-in-transit-enabled true \
    --ssh-authorized-keys-file "$D/vm_authorized_keys" \
    --query 'data.id' --raw-output 2>&1)

  id=$(grep -m1 -oE 'ocid1\.instance\.[^" ]+' <<<"$saida")
  if [[ -n $id ]]; then
    echo "$id" > "$FEITO"
    avisar "Oracle: VM $NOME criada na tentativa $tentativa! Abra Compute > Instances para ver o IP."
    exit 0
  fi

  espera=$INTERVALO
  case $saida in
    "") motivo="sem resposta" ;;
    *"Out of host capacity"*|*"Out of capacity"*) motivo="sem vaga" ;;
    *TooManyRequests*) motivo="limite de requisicoes"; espera=$((INTERVALO * 4)) ;;
    *InternalError*|*'"status": 50'[0234]*|*"timed out"*|*Connection*) motivo="erro transitorio" ;;
    *) msg=$(grep -m2 -oE '"(code|message)": "[^"]*"' <<<"$saida" | tr '\n' ' ')
       parar "${msg:-$(head -c 300 <<<"$saida")}" ;;
  esac

  # Log enxuto: a 1a tentativa e depois a cada 20 (~1 hora).
  (( tentativa == 1 || tentativa % 20 == 0 )) && log "tentativa $tentativa: $motivo"
  sleep $((espera + RANDOM % 30))
done
