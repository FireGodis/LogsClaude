# Skills e workflow de desenvolvimento

## Roblox Game Skill

Origem: [brockmartin/roblox-game-skill](https://github.com/brockmartin/roblox-game-skill/tree/main)  
Arquivo de entrada: [SKILL.md](https://github.com/brockmartin/roblox-game-skill/blob/main/SKILL.md)

Use esta referência em mudanças de Luau, arquitetura, segurança, persistência, UI, multiplayer, monetização e QA no Roblox. A skill orienta a identificar primeiro o modo de integração Studio realmente disponível e direciona o trabalho para workflows e referências específicos, como jogo novo, tycoon/simulator, segurança, dados, performance e monetização.

Para STEAL A GOD, consultar também os workflows de jogo novo, o template de tycoon/simulator e as referências pertinentes ao sistema em alteração. O projeto real deve ser inspecionado antes de escolher estrutura ou instalar ferramentas.

## Blender SuperSkill

Origem: [powerhouse90/Blender-Superskill](https://github.com/powerhouse90/Blender-Superskill)  
Arquivo de entrada: [skills/blender-superskill/SKILL.md](https://github.com/powerhouse90/Blender-Superskill/blob/main/skills/blender-superskill/SKILL.md)

Use quando a tarefa tocar criação, revisão ou crítica de assets Blender. O fluxo enfatiza referências visuais claras, anatomia/proporções, construção em etapas, inspeção de viewport e verificação numérica das faces de contato quando partes se alinham. Para modelos complexos orientados por referência, consulte o orchestrator incluído no repositório da skill e siga as instruções aplicáveis.

Para STEAL A GOD, aplique o fluxo a ovos, deuses, cenários, bases, props, rigging e animações que sejam modelados no Blender. Registre fonte, exportação, pivô, escala, colisão e validação no [ASSET_MANIFEST.md](ASSET_MANIFEST.md).

## Limites de uso

- As skills são referências externas mutáveis; verifique a versão e instruções no repositório de origem ao iniciar uma tarefa relevante.
- Não copie instruções ou scripts de terceiros para esta pasta sem necessidade. Os links acima são os pontos de entrada.
- Não declare integração, exportação ou ferramenta disponível sem verificá-la no ambiente real.
- Os requisitos específicos do GDD ficam em [MASTER_GAME_DESIGN.md](MASTER_GAME_DESIGN.md); registra-se qualquer alteração de escopo no log compartilhado.

## Aplicação das skills — 2026-11-03

- A Roblox Game Skill foi consultada para workflow de projeto, estrutura de tycoon/simulator, autoridade do servidor, persistência e segurança. A implementação usa pastas modulares, configuração central, lógica econômica server-side e HUD de leitura.
- A Blender SuperSkill foi consultada como referência, mas modelagem Blender/ForgeGUI não foi necessária nesta fatia: o mapa e a estátua são Parts procedurais e o rig é criado pelo Roblox em runtime.
- O próximo trabalho de arte que produza modelos finais deve aplicar o fluxo de referência, medidas e validação de export/import descrito pela Blender SuperSkill.
