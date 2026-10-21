# WARCORE v2 — Notas de atualização

## 21/10/2026 — Vida, cooldown e teleporte

### Teleporte
- Removido por completo o teleporte por toque/duplo toque: seleção no mapa,
  confirmação, marcador, linha neon e limite de distância.
- Mantidos o painel de teleporte, destino salvo, ANTI-VOID e o botão
  "Teleportar até o Inimigo Mais Próximo".

### Vida
- Novo toggle "Regeneração Rápida de Vida".
- Novo slider "Velocidade de Regeneração (HP/s)" de 1 a 200.

### Habilidades
- Novo toggle "Reduzir Cooldown das Habilidades (Tools)".
- O script zera cooldowns numéricos e atributos de cooldown nas Tools do
  Backpack/Character e reativa a Tool quando ela é desabilitada pelo jogo.

### Validação
- Sintaxe verificada com `luac -p` (OK).

### Arquivos alterados
- `WARCOREV2.lua` (renomeado de `WARCORE0.lua`)
- `CHANGELOG.md`

## 21/10/2026

### Botões da janela
- `–` (minimizar): apenas oculta o menu. Nenhum sistema é desligado.
- `×` (fechar): desligamento total (panic). Fecha o menu, painéis e notificações e desativa:
  mira assistida, RX/Highlight, ponto na cabeça, linhas, ESP, barra de vida, FOV,
  Micro-HUD, FPS/Players, FullBright, Clareza, sombras, horário fixo, Fly, Speed,
  Super Pulo, Pulo Infinito, No-Clip, teleporte, teleporte por toque e anti-AFK.
- O desligamento também restaura iluminação, WalkSpeed e JumpPower originais,
  sincroniza todos os toggles para OFF e limpa os overlays imediatamente.
- O botão flutuante continua disponível para reabrir o menu (com tudo desligado).

### Interface
- Nova paleta "TACTICAL EMBER": verde ácido + laranja brasa sobre grafite.
- Fonte mono (Code) em valores e notificações.
- Notificações no estilo `// SYS.ALERT`.
- Utilitários visuais de HUD adicionados: cantos (brackets), scanlines,
  grade tática e marca lateral dos controles.

### Validação
- Sintaxe verificada com `loadfile` (OK).

### Arquivos alterados
- `WARCORE0.lua`
- `CHANGELOG.md`
