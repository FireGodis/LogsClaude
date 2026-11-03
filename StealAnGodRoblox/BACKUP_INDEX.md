# Índice de backups

## Escopo atual — 2026-11-03

A especificação mestre enviada pelo usuário está em [MASTER_GAME_DESIGN.md](MASTER_GAME_DESIGN.md) e é versionada no histórico Git do repositório LogsClaude.

**Não há backup binário do place nem dos assets externos.** Foi criado um snapshot dos oito scripts Luau extraídos do Roblox Studio em [source_snapshot/2026-11-03/README.md](source_snapshot/2026-11-03/README.md). O mapa é gerado pelo WorldBuilder; os assets desta fatia são placeholders procedurais.

## Registro

| Data | Origem / place | Conteúdo | Local e formato | Validação | Limitações |
|---|---|---|---|---|---|
| 2026-11-03 | Anexo do usuário: GDD STEAL A GOD | Documento mestre de design | MASTER_GAME_DESIGN.md, Markdown | Conteúdo integral preservado | Não inclui código ou assets |
| 2026-11-03 | [☀️UPD] Steal An God, place ID 129275930788382 | Oito scripts Luau, incluindo mapa procedural, dados, jogo, Ares, bootstrap e HUD | source_snapshot/2026-11-03, arquivos .lua + README | Lidos do DataModel após playtest e conferidos no Studio | Não inclui .rbxlx, estado binário do place ou assets externos |

O DataStore ficou em modo de memória durante os playtests. O snapshot de código não substitui exportação/salvamento do place.

## Convenção para futuras cópias

Antes de criar uma cópia, registrar origem, data, versão/place, conteúdo, caminho e formato, integridade ou hash quando aplicável, método de restauração e limitações. Para snapshots futuros, prefira uma subpasta datada como backups/AAAA-MM-DD/codigo/ ou backups/AAAA-MM-DD/assets/.

Confirme limites de tamanho e se o conteúdo pode ser publicado antes de adicionar arquivos binários. Não inclua tokens, credenciais, dados pessoais ou arquivos temporários. Não descreva como backup uma cópia que não foi criada e verificada.
