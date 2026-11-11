# 001 — vSphere 8 perde o suporte em 2027

Dois scripts **somente leitura** com o [govc](https://github.com/vmware/govmomi/tree/main/govc) (linha de comando oficial do govmomi). Eles só consultam o inventário e não alteram nada.

| Script | O que faz |
|---|---|
| `inventario-vsphere8.sh` | Mostra o vCenter (versão e build) e cada host ESXi com versão, build, sockets e cores. No fim, conta os hosts 8.x, soma os cores físicos e calcula quantos dias faltam para 11/10/2027 (fim do suporte geral do vSphere 8, Broadcom KB 459135) |
| `checagem-patch-licenca.sh` | Para cada ESXi 8.x: compara o build com o build corrigido da **VMSA-2026-0006** (ESXi 8.0 U3k = 25595708) e calcula os cores licenciáveis com o mínimo de 16 cores por CPU. Também diz se o total cabe no vSphere Express (128 cores) |

## Requisitos
- `govc` e `jq`
- bash 4+, `awk` e `date` do GNU (Linux)

## Rodar contra o vcsim (simulador)
```bash
vcsim -l 127.0.0.1:8989 &                 # ou: docker run -p 8989:8989 vmware/vcsim
export GOVC_URL='https://usuario@127.0.0.1:8989/sdk'
export GOVC_PASSWORD='qualquer-senha'     # o vcsim aceita qualquer senha
export GOVC_INSECURE=1
./inventario-vsphere8.sh
./checagem-patch-licenca.sh
```
O inventário padrão do vcsim tem hosts com poucos cores. No vídeo, as CPUs dos hosts foram ajustadas no modelo do simulador (4 hosts com 2×8 cores e 3 hosts com 2×24 cores).

## Rodar contra um vCenter de laboratório
```bash
export GOVC_URL='https://usuario@vcenter.lab.local/sdk'
read -rs GOVC_PASSWORD && export GOVC_PASSWORD   # nunca grave a senha no script
# GOVC_INSECURE=1 só em laboratório com certificado autoassinado
./inventario-vsphere8.sh
./checagem-patch-licenca.sh
```
Use um usuário só de leitura.

## Limitações
- A checagem de patch compara números de build: ela serve para **triagem**. Para decidir, confira a matriz oficial do advisory VMSA-2026-0006 (Broadcom, ID 38017), que também lista a correção do ramo 8.0 U2 (U2f, build 25626445). O vCenter fica fora da comparação, porque o advisory só informa a versão corrigida (8.0 U3k / U2f), sem o número de build.
- A regra de mínimo de 16 cores por CPU é a divulgada pela Broadcom (KB 313548). Preços, mínimos por pedido e multas variam por contrato: confirme com o seu revendedor.

## Fontes
- Broadcom KB 459135: fim do suporte geral do vSphere 8.0
- Broadcom advisory VMSA-2026-0006 (ID 38017)
- Broadcom KB 313548: contagem de cores para VCF/VVF
- github.com/vmware/govmomi (govc e vcsim)
