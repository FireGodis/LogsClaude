# Histórico — Fase 5: Habilidades à la Silksong

## 2026-11-02 — avanço inicial

- **Região da Vila das Lanternas — Asa de Bruma (`wings`):** Lumeira concede habilidade ao concluir diálogo. Durante o ar, segundo pressionar do pulo aplica impulso controlado uma vez até aterrissar; peças de asa usam WedgeParts originais com animação oscilante; burst de partículas e cues existentes `flap`/`flap2`. Pode combinar com dash, sujeito a teste de física.
- **Região Alameda de Musgo — Garra de Raiz (`claw`):** Orvalho concede ao concluir diálogo. Ao detectar parede lateral durante o ar, salto impulsiona para longe, aplica breve controle direcional e wall slide limita queda. A reutilização libera ao pousar ou tocar parede oposta. VFX usa burst procedural e cue existente `wall`.
- **Progressão:** servidor valida perfil e cooldown e replica os atributos. WorldSystem só concede após diálogo iniciada por ProximityPrompt; habilidade e flag persistem pelo perfil quando DataStore funciona.
- **Animação/FX/SFX:** animação de asas já tinha lógica inativa; agora há partes/grupos adequados. VFX é código original; som não é inédito.
- **Aplicação no mapa:** habilidade de garra tem utilidade no Jardim/shafts, mas ainda não foi associada a uma porta física; nenhum portão foi alterado.
- **Testes:** modules carregaram e wings foi concedida no Play. Impulso, wall jump, segurança de cooldown e save não foram validados em teste físico.
- **Estado:** **Em andamento**, sem concluir a fase.