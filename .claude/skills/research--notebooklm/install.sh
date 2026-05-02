#!/usr/bin/env bash
# Instala el módulo NotebookLM en un proyecto de Claude Code.
#
# Uso:
#   ./research--notebooklm/install.sh                        # instala en el directorio actual
#   ./research--notebooklm/install.sh /ruta/a/mi-proyecto    # instala en el proyecto indicado

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROJECT="${1:-$(pwd)}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}>> $1${NC}"; }
ok()   { echo -e "   ${GREEN}OK${NC}  $1"; }
warn() { echo -e "   ${YELLOW}WARN${NC} $1"; }
fail() { echo -e "   ${RED}ERR${NC}  $1"; exit 1; }

# ─── 1. Verificar proyecto target ──────────────────────────────────────────────
step "Proyecto target: $TARGET_PROJECT"
[ -d "$TARGET_PROJECT" ] || fail "El directorio no existe: $TARGET_PROJECT"
ok "Directorio encontrado"

# ─── 2. Instalar notebooklm-mcp-cli ────────────────────────────────────────────
step "Verificando notebooklm-mcp-cli"

if command -v notebooklm-mcp &>/dev/null; then
    MCP_BIN="$(command -v notebooklm-mcp)"
    ok "Ya instalado: $MCP_BIN"
else
    echo "   Instalando notebooklm-mcp-cli..."

    if command -v uv &>/dev/null; then
        echo "   Usando: uv"
        uv tool install notebooklm-mcp-cli
    elif command -v pipx &>/dev/null; then
        echo "   Usando: pipx"
        pipx install notebooklm-mcp-cli
    elif command -v pip &>/dev/null; then
        echo "   Usando: pip"
        pip install notebooklm-mcp-cli
    else
        fail "No se encontró uv, pipx ni pip. Instala uno primero.\n   Recomendado: https://docs.astral.sh/uv/getting-started/installation/"
    fi

    MCP_BIN="$(command -v notebooklm-mcp 2>/dev/null || true)"
    [ -n "$MCP_BIN" ] || fail "notebooklm-mcp no encontrado después de instalar. Verifica tu PATH."
    ok "Instalado: $MCP_BIN"
fi

# ─── 3. Copiar skill al proyecto target ────────────────────────────────────────
step "Instalando skill /research--notebooklm"

SKILL_SRC="$SCRIPT_DIR/skill.md"
SKILL_DIR="$TARGET_PROJECT/.claude/skills"
SKILL_DST="$SKILL_DIR/research--notebooklm.md"

mkdir -p "$SKILL_DIR"
cp "$SKILL_SRC" "$SKILL_DST"
ok "Skill copiado a: $SKILL_DST"

# ─── 4. Inyectar snippet en CLAUDE.md del proyecto target ──────────────────────
step "Actualizando CLAUDE.md del proyecto"

SNIPPET_FILE="$SCRIPT_DIR/claude-snippet.md"
CLAUDE_MD="$TARGET_PROJECT/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
    if grep -q "NotebookLM" "$CLAUDE_MD" 2>/dev/null; then
        warn "CLAUDE.md ya menciona NotebookLM — no se modificó"
    else
        echo "" >> "$CLAUDE_MD"
        cat "$SNIPPET_FILE" >> "$CLAUDE_MD"
        ok "Snippet agregado a: $CLAUDE_MD"
    fi
else
    warn "No hay CLAUDE.md en el proyecto — créalo si quieres que Claude conozca el módulo"
fi

# ─── 5. Agregar MCP a .claude/settings.json del proyecto target ────────────────
step "Configurando MCP en el proyecto"

SETTINGS_DIR="$TARGET_PROJECT/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

if [ -f "$SETTINGS_FILE" ]; then
    if python3 -c "import json,sys; d=json.load(open('$SETTINGS_FILE')); sys.exit(0 if 'notebooklm' in d.get('mcpServers',{}) else 1)" 2>/dev/null; then
        warn "MCP 'notebooklm' ya existe en settings.json — no se modificó"
    else
        python3 - "$SETTINGS_FILE" "$MCP_BIN" <<'EOF'
import json, sys
path, bin_path = sys.argv[1], sys.argv[2]
with open(path) as f:
    d = json.load(f)
d.setdefault("mcpServers", {})["notebooklm"] = {"command": bin_path}
with open(path, "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write("\n")
EOF
        ok "MCP agregado con comando: $MCP_BIN"
    fi
else
    python3 - "$SETTINGS_FILE" "$MCP_BIN" <<'EOF'
import json, sys
path, bin_path = sys.argv[1], sys.argv[2]
d = {"mcpServers": {"notebooklm": {"command": bin_path}}}
with open(path, "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write("\n")
EOF
    ok "Settings creado: $SETTINGS_FILE"
fi

# ─── 6. Verificar autenticación ────────────────────────────────────────────────
step "Verificando autenticación con NotebookLM"

AUTH_OK=false
if command -v nlm &>/dev/null; then
    if nlm profile list &>/dev/null 2>&1; then
        AUTH_OK=true
    fi
fi

if $AUTH_OK; then
    ok "Autenticación encontrada"
else
    warn "No hay sesión activa. Ejecuta: nlm login"
    echo "   (Abre Chrome y pide login con tu cuenta Google)"
fi

# ─── 7. Resumen final ──────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────"
echo -e " ${GREEN}Módulo NotebookLM instalado correctamente${NC}"
echo "─────────────────────────────────────────"
echo ""
echo " Proyecto: $TARGET_PROJECT"
echo " Skill:    $SKILL_DST"
echo " Settings: $SETTINGS_FILE"
echo ""
if ! $AUTH_OK; then
    echo -e " ${YELLOW}PENDIENTE: Ejecuta 'nlm login' para autenticarte${NC}"
    echo ""
fi
echo " Uso en Claude Code:"
echo "   /research--notebooklm             → inicia el asistente de research"
echo "   /research--notebooklm listar      → muestra tus cuadernos"
echo "   /research--notebooklm consultar   → pregunta a un cuaderno con citas"
echo ""
echo " Documentación completa de herramientas: nlm --ai"
echo ""
