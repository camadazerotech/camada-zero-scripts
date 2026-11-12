# 002 — Licenciamento VMware: contando cores do jeito certo

Um script **somente leitura** com o [govc](https://github.com/vmware/govmomi/tree/main/govc) (linha de comando oficial do govmomi). Ele só consulta o inventário e não altera nada.

| Script | O que faz |
|---|---|
| `calculo-licenca.sh` | Lê CPUs e cores de cada host, aplica a regra da Broadcom (KB 313548: mínimo de 16 cores por CPU, somados por host) e mostra o resultado por host, por cluster e no total. Compara a capacidade bruta de vSAN que você informar com o vSAN incluído na edição (VCF: 1 TiB por core; VVF: 0,25 TiB por core, arredondado para cima) e diz se o total cabe no vSphere Express (128 cores) |

## Requisitos
- `govc` e `jq`
- bash 4+ e `awk` (Linux)

## Uso
```bash
./calculo-licenca.sh [EDICAO] [VSAN_TIB_BRUTO]
# EDICAO: VCF (padrão) ou VVF
# VSAN_TIB_BRUTO: capacidade BRUTA dos discos do vSAN, em TiB (padrão: 0). Não é a capacidade do datastore
```
O datacenter padrão é `DC0` (o do vcsim). Para outro nome, defina `GOVC_DATACENTER`.

## Rodar contra o vcsim (simulador)
```bash
vcsim -l 127.0.0.1:8989 &                 # ou: docker run -p 8989:8989 vmware/vcsim
export GOVC_URL='https://usuario@127.0.0.1:8989/sdk'
export GOVC_PASSWORD='qualquer-senha'     # o vcsim aceita qualquer senha
export GOVC_INSECURE=1
./calculo-licenca.sh VCF 300
./calculo-licenca.sh VVF 100
```
O inventário padrão do vcsim tem hosts com poucos cores. No vídeo, as CPUs dos hosts foram ajustadas no modelo do simulador (4 hosts com 2×8 cores e 3 hosts com 2×24 cores), o mesmo laboratório do vídeo 001. Com esse modelo, o total é de 208 cores físicos e 272 licenciáveis.

## Rodar contra um vCenter de laboratório
```bash
export GOVC_URL='https://usuario@vcenter.lab.local/sdk'
read -rs GOVC_PASSWORD && export GOVC_PASSWORD   # nunca grave a senha no script
export GOVC_DATACENTER='NomeDoDatacenter'
# GOVC_INSECURE=1 só em laboratório com certificado autoassinado
./calculo-licenca.sh VCF 0
```
Use um usuário só de leitura.

## Limitações
- Supõe CPUs iguais dentro do host (cores por CPU = cores do host ÷ CPUs).
- Cores desativados na BIOS não aparecem na contagem. A KB 313548 pede todos os cores ativos.
- O vSAN bruto não é lido pelo script: informe o valor. A ferramenta oficial da Broadcom, indicada na KB 313548, faz essa leitura.
- O script grava dois arquivos temporários em `/tmp` (`licenca.tsv` e `licenca2.tsv`).
- O resultado é uma **estimativa para conferência**. Preços, mínimos por pedido, multas e disponibilidade de cada edição variam por região e contrato: confirme com o seu distribuidor.

## Fontes
- Broadcom KB 313548: contagem de cores para VCF/VVF e de TiB para vSAN — https://knowledge.broadcom.com/external/article/313548
- vSphere Express: anúncio da Broadcom de 04/11/2026 — https://blogs.vmware.com/cloud-foundation/2026/11/04/broadcom-vcf-portfolio-updates/
- vSphere Express na documentação — https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere/9-1/vsphere-express.html
- github.com/vmware/govmomi (govc e vcsim)
