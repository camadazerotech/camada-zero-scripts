# Camada Zero: scripts dos vídeos

Scripts mostrados nos vídeos do canal **Camada Zero** no YouTube ([@camadazerotech](https://www.youtube.com/@camadazerotech)): virtualização e infraestrutura em português.

Cada vídeo tem uma pasta própria, com os scripts e um README explicando o que eles fazem e como rodar.

| Vídeo | Pasta | O que tem |
|---|---|---|
| 001 — vSphere 8 perde o suporte em 2027 | [`001-vsphere8-fim-suporte/`](001-vsphere8-fim-suporte/) | Inventário de versões e cores; checagem da correção VMSA-2026-0006 e cores licenciáveis (govc, somente leitura) |
| 002 — Licenciamento VMware: contando cores do jeito certo | [`002-licenciamento-vmware-cores/`](002-licenciamento-vmware-cores/) | Cálculo de cores licenciáveis por host e cluster (KB 313548), vSAN incluído em VCF/VVF e teste do limite do vSphere Express (govc, somente leitura) |

## ⚠️ Aviso

Este conteúdo é estritamente educacional. Qualquer script, código ou configuração deve ser testado em ambiente de homologação (laboratório) antes de ser aplicado em produção. O canal e o criador não se responsabilizam por eventuais erros, indisponibilidades ou perdas de dados decorrentes da execução destes procedimentos.

- As demonstrações dos vídeos rodam no **vcsim**, o simulador oficial e open source do vCenter/ESXi ([vmware/govmomi](https://github.com/vmware/govmomi)).
- Os scripts são **somente leitura**, salvo quando o README da pasta disser o contrário.
- Informações de versões, builds e licenciamento mudam. Confira sempre a documentação oficial da Broadcom indicada em cada pasta.

## Licença

[MIT](LICENSE).
