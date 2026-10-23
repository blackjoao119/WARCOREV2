# WARCORE v2 — Notas de atualização

## 23/10/2026 — Invisibilidade e Instinto Superior V2

### Invisibilidade
- Novo toggle "Ficar Invisível (Local)" na aba Visual.
- Aplica `LocalTransparencyModifier = 1` e `Transparency = 1` em todas as
  partes do personagem, guardando a transparência original para restaurar.
- Funciona com acessórios, reaplica ao trocar de personagem e é restaurada
  pelo botão de desligamento total.
- Keybind opcional em Keybinds e autosave da opção.

### Instinto Superior V2 (Auto Esquiva)
- Novo toggle "Instinto Superior V2 (Auto Esquiva)" na aba Combate.
- Detecta projéteis em movimento, hitboxes/poderes por nome e golpes de
  jogadores com Tool equipada em um raio configurável.
- Desvia lateralmente com dash curto, respeitando cooldown.
- Sliders: Raio de Detecção (10–120), Distância da Esquiva (4–40) e
  Cooldown da Esquiva (0,1–2 s).
- Keybind opcional em Keybinds e autosave das opções.

### Validação
- Sintaxe verificada com `luac -p` (OK).
- Harness simulado: liga/desliga da invisibilidade, desvio de projétil,
  cooldown e restauração no desligamento total (todos OK).

### Arquivos alterados
- `WARCOREV2.lua`
- `WARCORE0.lua` (alias)
- `CHANGELOG.md`

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
