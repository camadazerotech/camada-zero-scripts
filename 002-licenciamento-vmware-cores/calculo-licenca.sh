#!/usr/bin/env bash
# =============================================================================
# calculo-licenca.sh — Camada Zero, vídeo 002
# Calcula, por cluster, os cores licenciáveis pela regra oficial da Broadcom
# (KB 313548: mínimo de 16 cores por CPU, somados por host) e compara a
# capacidade bruta de vSAN informada com o direito incluído na edição.
#
# SOMENTE LEITURA. Requisitos: govc (github.com/vmware/govmomi) e jq.
# Uso:
#   export GOVC_URL='https://usuario:senha@vcenter/sdk'   # no laboratório: vcsim
#   ./calculo-licenca.sh [EDICAO] [VSAN_TIB_BRUTO]
#     EDICAO          VCF (1 TiB de vSAN por core) ou VVF (0,25 TiB por core,
#                     arredondado para cima). Padrão: VCF
#     VSAN_TIB_BRUTO  capacidade BRUTA que os hosts entregam ao vSAN, em TiB
#                     (não é a capacidade do datastore). Padrão: 0
#
# Limitações:
#  - Supõe CPUs iguais dentro do host (cores por CPU = cores do host / CPUs).
#  - Cores desativados na BIOS não aparecem: a KB pede todos os cores ativos.
#  - O vSAN bruto não é lido aqui: informe o valor (ferramenta oficial da KB
#    313548 ou o seu inventário de discos).
#  - Hosts fora de cluster entram como "(sem cluster)".
#
# Conteúdo educacional: teste em homologação antes de usar em produção.
# =============================================================================
set -euo pipefail

EDICAO="${1:-VCF}"
VSAN_TIB="${2:-0}"
MIN_POR_CPU=16      # KB 313548
LIMITE_EXPRESS=128  # vSphere Express: pacote único de 128 cores por cliente

coletar() {  # $1 = caminho do inventário; imprime host, CPUs, cores (TSV)
  govc object.collect -json -type h "$1" name summary.hardware.numCpuPkgs summary.hardware.numCpuCores \
  | jq -s -r '[ .[] | (.changeSet // .ChangeSet) | map({ (.name // .Name): (.val // .Val) }) | add ]
              | .[] | [ .name, .["summary.hardware.numCpuPkgs"], .["summary.hardware.numCpuCores"] ] | @tsv'
}

: > /tmp/licenca.tsv
for c in $(govc ls -t ClusterComputeResource "/${GOVC_DATACENTER:-DC0}/host"); do
  coletar "$c" | sed "s|^|$(basename "$c")\t|" >> /tmp/licenca.tsv
done
# hosts avulsos (ComputeResource que não é cluster)
for h in $(govc ls -t ComputeResource "/${GOVC_DATACENTER:-DC0}/host"); do
  coletar "$h" | sed "s|^|(sem cluster)\t|" >> /tmp/licenca.tsv
done

# cluster, host, CPUs, cores físicos, cores licenciáveis = CPUs x max(cores/CPU, 16)
awk -F'\t' -v min="$MIN_POR_CPU" 'BEGIN{OFS="\t"} {por=$4/$3; l=$3*(por>min?por:min); print $1,$2,$3,$4,l}' \
  /tmp/licenca.tsv | sort > /tmp/licenca2.tsv

printf "%-14s %-12s %5s %6s %13s\n" CLUSTER HOST CPUS CORES "LICENCIÁVEIS"
awk -F'\t' '{printf "%-14s %-12s %5s %6s %12s\n",$1,$2,$3,$4,$5}' /tmp/licenca2.tsv
echo
echo "== Por cluster =="
awk -F'\t' '{f[$1]+=$4; l[$1]+=$5} END {for (c in f) printf "%-14s físicos %4d | licenciáveis %4d | +%d%%\n", c, f[c], l[c], (l[c]-f[c])*100/f[c]}' \
  /tmp/licenca2.tsv | sort

fis=$(awk -F'\t' '{s+=$4} END{print s+0}' /tmp/licenca2.tsv)
lic=$(awk -F'\t' '{s+=$5} END{print s+0}' /tmp/licenca2.tsv)
echo
echo "== Total =="
echo "Cores físicos: $fis  |  cores licenciáveis: $lic"

# vSAN: direito incluído na edição x capacidade bruta informada
case "$EDICAO" in
  VCF) direito=$lic ;;                                  # 1 TiB por core
  VVF) direito=$(( (lic + 3) / 4 )) ;;                   # 0,25 TiB por core, arredondado para cima
  *)   echo "EDICAO deve ser VCF ou VVF"; exit 1 ;;
esac
echo "vSAN incluído no $EDICAO: ${direito} TiB  |  bruto informado: ${VSAN_TIB} TiB"
if [ "$VSAN_TIB" -gt "$direito" ]; then
  echo "  -> faltam $(( VSAN_TIB - direito )) TiB de vSAN (capacidade adicional)"
else
  echo "  -> o direito incluído cobre o vSAN informado"
fi

# vSphere Express: pacote fixo de 128 cores (fontes: anúncio de 04/11/2026 e distribuidores)
if [ "$lic" -le "$LIMITE_EXPRESS" ]; then
  echo "vSphere Express (${LIMITE_EXPRESS} cores): cabe"
else
  echo "vSphere Express (${LIMITE_EXPRESS} cores): não cabe (${lic} > ${LIMITE_EXPRESS})"
fi
