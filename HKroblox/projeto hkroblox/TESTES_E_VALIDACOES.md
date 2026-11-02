# Testes e validações

## 2026-11-02 — linha de base estática

- **Engine/linguagem:** place Roblox Studio, scripts Luau com anotação strict.
- **Feito:** árvores de Workspace, ReplicatedStorage, ServerScriptService, StarterPlayer e StarterGui; leitura dos módulos Input, Movement, Cutscene, KnightAnim, PlayerData, WorldSystem, Combat, Config, KnightSpec e WorldMap; busca por diálogo; contagem de objetos principais.
- **Resultado:** 14 salas e seis biomas no WorldMap; 204 partes na pasta Plataformas (102 plataformas sólidas e 102 brilhos); seis modelos de banco; cinco colecionáveis; uma barreira. `StarterGui` não possui filhos no modo Edit.
- **Sintaxe:** não foi executada análise/compilação automatizada.
- **Referências:** leitura estática confirma caminhos de require consultados, mas não prova que o place inicia sem erros.
- **DataStore:** não validado; o Studio pode usar perfil temporário quando não consegue carregar.
- **Playtest:** não executado nesta etapa.
- **Visual:** nenhuma captura de tela do place foi obtida nesta análise; imagens do usuário foram tratadas apenas como referências.
- **Conclusão:** linha de base parcial; nenhuma funcionalidade comportamental declarada validada.

Registrar cada rodada com cenário, procedimento, resultado observado, console e limitações.
