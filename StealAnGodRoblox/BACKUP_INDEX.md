# Índice de backups

## Escopo atual — 2026-11-03

A especificação mestre enviada pelo usuário foi copiada para [MASTER_GAME_DESIGN.md](MASTER_GAME_DESIGN.md) e está versionada no histórico Git de LogsClaude.

**Não há backup binário do place nem dos assets.** Os scripts Luau foram copiados de Studio para source_snapshot/2026-11-03; esse backup de fontes não substitui um arquivo .rbxlx e não inclui assets externos.

## Registro de cópias\n\n| Data | Origem / place ou commit | Conteúdo | Local e formato | Integridade / hash | Commit que adicionou | Limitações |\n|---|---|---|---|---|---|---|\n| 2026-11-03 | Anexo do usuário: GDD STEAL A GOD | Documento mestre de design | MASTER_GAME_DESIGN.md, Markdown | Conteúdo integral preservado | Commit inicial | Não inclui código, place ou assets |\n| 2026-11-03 | Place [☀️UPD] Steal An God, ID 129275930788382 | Oito scripts Luau do DataModel | source_snapshot/2026-11-03 | Copiado após playtest | Commits do snapshot | Não inclui .rbxlx, binários ou assets externos |\n\n## Registro de cópias futuras

Antes de criar uma cópia, registrar:

| Data | Origem / place ou commit | Conteúdo | Local e formato | Integridade / hash | Commit que adicionou | Limitações |
|---|---|---|---|---|---|---|
| 2026-11-03 | Anexo do usuário: GDD STEAL A GOD | Documento mestre de design | MASTER_GAME_DESIGN.md, Markdown | Conteúdo integral preservado | Commit inicial | Não inclui código, place ou assets |\n| 2026-11-03 | Place [☀️UPD] Steal An God, ID 129275930788382 | Oito scripts Luau do DataModel | source_snapshot/2026-11-03, Markdown/arquivos .lua | Copiado após playtest; restauração documentada | Commits do snapshot | Não inclui arquivo .rbxlx, binários ou assets externos |

## Convenção

Para snapshots futuros, prefira uma subpasta datada e identificada pelo escopo, por exemplo: backups/AAAA-MM-DD/codigo/ ou backups/AAAA-MM-DD/assets/. Acompanhe cada snapshot com origem, versão, arquivos incluídos, formato, tamanho ou hash quando aplicável, método de restauração e commit Git.

Confirme limites de tamanho e se o conteúdo pode ser publicado antes de adicionar arquivos binários. Não inclua tokens, credenciais, dados pessoais ou arquivos temporários. Não descreva como backup uma cópia que não foi criada e verificada.

## Snapshot dos fontes do Roblox Studio — 2026-11-03

Foi criado source_snapshot/2026-11-03 com os oito scripts Luau lidos do DataModel do place 129275930788382 e um README de restauração. Inclui configuração, serviços de dados/mundo/jogo/IA, bootstrap, UIConfig e HUD. O código foi criado para ser versionado como backup e handoff.

O snapshot não contém um place binário .rbxlx, assets externos ou estado salvo de DataModel. O mapa é gerado pelo WorldBuilder e os assets desta fatia são placeholders procedurais. DataStore em modo Studio foi desativado deliberadamente nos playtests. O README do snapshot explica restauração e limites.
