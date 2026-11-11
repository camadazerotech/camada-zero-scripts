#!/usr/bin/env bash
# =============================================================================
# inventario-vsphere8.sh — Dark Channel, vídeo 001
# Lista vCenter e hosts ESXi com versão, build, sockets e cores, e conta
# quantos dias faltam para o fim do suporte geral do vSphere 8 (11/10/2027,
# Broadcom KB 459135).
#
# SOMENTE LEITURA: não altera nada no vCenter.
# Requisitos: govc (github.com/vmware/govmomi) e jq.
# Uso:
#   export GOVC_URL='https://usuario@vcenter.lab.local/sdk'   # seu vCenter de LAB
#   export GOVC_PASSWORD='...'                               # nunca no script
#   export GOVC_INSECURE=1     # só em laboratório com certificado autoassinado
#   ./inventario-vsphere8.sh
#
# Conteúdo educacional: teste em homologação antes de usar em produção.
# =============================================================================
set -euo pipefail

EOGS="2027-10-11"   # fim do suporte geral do vSphere 8 (KB 459135)

# 1) Quem é o vCenter? (nome do produto, versão e build)
echo "== vCenter =="
govc about -json | jq -r '.about | "\(.name)  |  Versão: \(.version)  |  Build: \(.build)"'
echo

# 2) Todos os hosts ESXi do inventário, com versão, build, sockets e cores.
#    "-type h" = HostSystem. As propriedades vêm do objeto summary do host.
echo "== Hosts ESXi =="
govc object.collect -json -type h / \
  name \
  summary.config.product.version \
  summary.config.product.build \
  summary.hardware.numCpuPkgs \
  summary.hardware.numCpuCores \
| jq -s -r '
    # Cada linha da saída é um host; transformamos a lista de propriedades
    # em um objeto {nome_da_propriedade: valor}.
    [ .[] | (.changeSet // .ChangeSet) | map({ (.name // .Name): (.val // .Val) }) | add ]
    | sort_by(.name)
    | (["HOST", "VERSÃO", "BUILD", "SOCKETS", "CORES"] | @tsv),
      ( .[] | [ .name,
                .["summary.config.product.version"],
                .["summary.config.product.build"],
                .["summary.hardware.numCpuPkgs"],
                .["summary.hardware.numCpuCores"] ] | @tsv )
  ' | awk -F'\t' '{ w = (NR==1) ? 9 : 8   # "VERSÃO" tem acento: 1 byte a mais
                  printf "%-12s %-*s %-10s %8s %6s\n", $1, w, $2, $3, $4, $5 }' \
  | tee /tmp/inventario_hosts.txt   # alinha as colunas e guarda para o resumo
echo

# 3) Resumo: hosts na linha 8.x, total de cores e dias até o fim do suporte.
total_v8=$(awk 'NR>1 && $2 ~ /^8\./' /tmp/inventario_hosts.txt | wc -l)
total_cores=$(awk 'NR>1 {s+=$5} END {print s+0}' /tmp/inventario_hosts.txt)
dias=$(( ( $(date -d "$EOGS" +%s) - $(date -d "$(date +%F)" +%s) ) / 86400 ))

echo "== Resumo =="
echo "Hosts ESXi 8.x: ${total_v8}"
echo "Cores físicos (total): ${total_cores}"
echo "Dias até ${EOGS} (fim do suporte geral do vSphere 8): ${dias}"
