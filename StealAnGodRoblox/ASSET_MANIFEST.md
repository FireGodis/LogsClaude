# Manifesto de assets

## Estado

Inventário baseado no GDD e na inspeção do place em Roblox Studio. O mapa grego e seus objetos são placeholders procedurais de Parts; o primeiro rival usa rig R15 criado pelo Roblox em runtime. Não há assets finais importados. Evidências e caminhos observados estão na seção de placeholders.

## Convenção de identificação proposta

IDs estáveis e legíveis: SAG_<TIPO>_<NOME>_<VARIANTE>_V<NN>. Exemplos de identificadores, ainda não atribuídos a arquivos reais:

- SAG_GOD_ZEUS_BASE_V01
- SAG_EGG_GREEK_BASE_V01
- SAG_ENV_ASGARD_HUB_V01

Nomes e convenções devem ser ajustados se o projeto existente já tiver um padrão estabelecido. Preserve o arquivo-fonte Blender e registre separadamente o artefato exportado e a referência importada no Roblox. O formato de exportação será decidido após verificar a ferramenta e o fluxo de importação disponíveis.

## Inventário inicial

| ID / grupo | Tipo | Origem planejada | Arquivo fonte | Exportação / Roblox | Estado |
|---|---|---|---|---|---|
| Olympus | Ambiente | Blender | A definir | A definir | Planejado; não verificado |
| Asgard | Ambiente | Blender | A definir | A definir | Planejado; não verificado |
| Egyptian Kingdom | Ambiente | Blender | A definir | A definir | Planejado; não verificado |
| Central Hub | Ambiente | Blender | A definir | A definir | Planejado; não verificado |
| Ovos Greek, Norse e Egyptian | Colecionáveis | Blender | A definir | A definir | Planejado; não verificado |
| Ovos Ancient, Celestial e Divine | Colecionáveis | Blender | A definir | A definir | Planejado; não verificado |
| Deuses representativos das três civilizações | Personagens | Blender | A definir | A definir | Selecionar na Fase 0/1 |
| Bases, slots e estruturas defensivas | Cenário / gameplay | Blender ou construção no Studio | A definir | A definir | Planejado; fluxo pendente |
| Rivais NPC | Personagens / rigs | Blender ou rig do projeto | A definir | A definir | Planejado; identidades no GDD |
| Ícones de ovos, deuses, moedas e UI | Imagens | A definir | A definir | A definir | Planejado; não verificado |
| Animações, efeitos e áudio | Animação / VFX / áudio | A definir | A definir | A definir | Planejado; não verificado |

Cada deus, ovo ou asset final deve ter entrada própria quando sua produção começar. As linhas por grupo acima não indicam assets já criados.

## Campos a preencher para cada asset

| Campo | Registro |
|---|---|
| ID e nome exibido | Identificador estável e nome usado no jogo |
| Categoria e civilização | Ambiente, deus, ovo, prop, UI, animação etc. |
| Fonte | Caminho do .blend ou ferramenta que criou o asset |
| Exportação | Caminho e versão do arquivo exportado |
| Referência Roblox | Asset ID, instância ou caminho no projeto, quando existir |
| Geometria | Contagem de polígonos ou métrica disponível |
| Transformação | Escala, orientação e pivô verificados |
| Colisão | Configuração e teste de colisão |
| Materiais e texturas | Referências, resolução e estado |
| Animação / áudio | Referências associadas, se houver |
| Validação | Data, plataforma/dispositivo, observação e resultado |
| Responsável / histórico | Agente, commit ou registro de alteração |

## Fluxo de produção

1. Confirmar a referência visual e identificar as proporções e partes principais.
2. Construir em etapas e revisar a silhueta em Blender antes de acumular detalhes.
3. Para superfícies que se conectam, definir limites e verificar medidas e contato.
4. Exportar pelo fluxo efetivamente disponível e importar no Studio.
5. Validar escala, orientação, pivô, materiais, colisão, animação e custo visual.
6. Atualizar este manifesto com caminhos, referências e resultado observado.

Para modelagem, consulte [SKILLS_AND_WORKFLOW.md](SKILLS_AND_WORKFLOW.md) e a Blender SuperSkill. Não marque placeholder como asset final; substituições e exceções devem ficar registradas.

## Placeholders observados no Studio — 2026-11-03

O place tem uma cena grega procedural básica criada no Roblox Studio. Estes elementos existem como placeholders feitos de Parts e materiais Roblox; não são assets finais nem modelos importados:

| Grupo | Caminho / evidência | Estado |
|---|---|---|
| Hub, altar grego e sete bases | Workspace.SAG_GameWorld; scripts WorldBuilder | Construído no Studio com Parts |
| Caminhos de mármore e bordas douradas | Workspace.SAG_GameWorld.SAG_Pathways | Procedurais |
| Estátua de Zeus | SAG_Base_XX após hatch | Placeholder de Parts |
| Ovo grego, pedestais e altares | Hub e bases | Placeholders de Parts |
| Ares | Rig R15 gerado em runtime por HumanoidDescription | Procedural; sem roupa/animação customizada |
| HUD | StarterPlayerScripts.SAG_HUD | Interface Roblox; sem ícones finais |

Não foi necessário usar Blender ou ForgeGUI neste slice. A Blender SuperSkill segue indicada para próxima etapa de assets de arte; nenhum .blend, FBX ou imagem externa foi produzido.
