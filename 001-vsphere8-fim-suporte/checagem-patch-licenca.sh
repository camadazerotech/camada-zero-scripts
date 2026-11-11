#!/usr/bin/env bash
# =============================================================================
# checagem-patch-licenca.sh — Dark Channel, vídeo 001 (demo 2)
# Para cada host ESXi 8.x:
#   1) compara o build com o build corrigido da VMSA-2026-0006
#      (ESXi 8.0 U3k = 25595708; matriz de resposta do advisory Broadcom 38017)
#   2) calcula os cores licenciáveis com a regra de mínimo de 16 cores por CPU
#      (regra divulgada por distribuidores; confirme na sua cotação)
#
# SOMENTE LEITURA. Requisitos: govc (github.com/vmware/govmomi) e jq.
# Uso: mesmas variáveis do inventario-vsphere8.sh (GOVC_URL, GOVC_PASSWORD...).
#
# Limitações (leia antes de usar):
#  - Comparação simplificada por número de build: build >= 25595708 = corrigido.
#    O ramo 8.0 U2 tem correção própria (U2f, build 25626445), que também passa
#    no teste. Para decisão, confira sempre a matriz oficial do advisory.
#  - O vCenter não entra na comparação: o advisory lista só a versão corrigida
#    (8.0 U3k / 8.0 U2f), sem número de build.
#
# Conteúdo educacional: teste em homologação antes de usar em produção.
# =============================================================================
set -euo pipefail

BUILD_CORRIGIDO=25595708   # ESXi80U3k-25595708 (VMSA-2026-0006)
MIN_POR_CPU=16             # mínimo de cores licenciados por CPU
LIMITE_EXPRESS=128         # vSphere Express: pacote fixo de 128 cores

govc object.collect -json -type h / \
  name \
  summary.config.product.version \
  summary.config.product.build \
  summary.hardware.numCpuPkgs \
  summary.hardware.numCpuCores \
| jq -s -r --argjson fix "$BUILD_CORRIGIDO" --argjson min "$MIN_POR_CPU" '
    [ .[] | (.changeSet // .ChangeSet) | map({ (.name // .Name): (.val // .Val) }) | add ]
    | sort_by(.name)
    | .[]
    | (.["summary.hardware.numCpuPkgs"]) as $cpu
    | (.["summary.hardware.numCpuCores"]) as $cores
    # cores licenciáveis = CPUs x máximo(cores por CPU, 16)
    | ($cpu * ([($cores / $cpu), $min] | max)) as $lic
    | [ .name,
        .["summary.config.product.build"],
        (if (.["summary.config.product.build"] | tonumber) >= $fix then "ok" else "PENDENTE" end),
        $cpu, $cores, $lic ] | @tsv
  ' > /tmp/checagem.tsv

printf "%-12s %-10s %-14s %7s %6s %13s\n" HOST BUILD "VMSA-2026-0006" CPUS CORES "LICENCIÁVEIS"
awk -F'\t' '{ printf "%-12s %-10s %-14s %7s %6s %12s\n", $1, $2, $3, $4, $5, $6 }' /tmp/checagem.tsv
echo

pendentes=$(awk -F'\t' '$3=="PENDENTE"' /tmp/checagem.tsv | wc -l)
fisicos=$(awk -F'\t' '{s+=$5} END {print s+0}' /tmp/checagem.tsv)
licenciaveis=$(awk -F'\t' '{s+=$6} END {print s+0}' /tmp/checagem.tsv)

echo "== Resumo =="
echo "Hosts sem o patch da VMSA-2026-0006: ${pendentes}"
echo "Cores físicos: ${fisicos}  |  cores licenciáveis (mín. ${MIN_POR_CPU}/CPU): ${licenciaveis}"
if [ "$fisicos" -le "$LIMITE_EXPRESS" ]; then
  echo "Cabe no vSphere Express (${LIMITE_EXPRESS} cores): sim"
else
  echo "Cabe no vSphere Express (${LIMITE_EXPRESS} cores): não"
fi
