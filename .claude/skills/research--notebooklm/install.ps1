#Requires -Version 5.1
<#
.SYNOPSIS
    Instala el modulo NotebookLM en un proyecto de Claude Code.

.DESCRIPTION
    Instala notebooklm-mcp-cli, copia el skill /research--notebooklm, configura
    el MCP server en el settings.json del proyecto target e inyecta
    un snippet en su CLAUDE.md.

.PARAMETER TargetProject
    Ruta al proyecto donde instalar el modulo.
    Por defecto: directorio de trabajo actual.

.EXAMPLE
    .\research--notebooklm\install.ps1
    .\research--notebooklm\install.ps1 -TargetProject "C:\mis-proyectos\mi-proyecto"
#>

param(
    [string]$TargetProject = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step { param($msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host "   OK  $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "   WARN $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "   ERR  $msg" -ForegroundColor Red }

# --- 1. Verificar proyecto target ---
Write-Step "Proyecto target: $TargetProject"
if (-not (Test-Path $TargetProject)) {
    Write-Fail "El directorio no existe: $TargetProject"
    exit 1
}
Write-Ok "Directorio encontrado"

# --- 2. Instalar notebooklm-mcp-cli ---
Write-Step "Verificando notebooklm-mcp-cli"

$mcpCmd = Get-Command notebooklm-mcp -ErrorAction SilentlyContinue
$mcpBin = if ($mcpCmd) { $mcpCmd.Source } else { $null }

if ($mcpBin) {
    Write-Ok "Ya instalado: $mcpBin"
} else {
    Write-Host "   Instalando notebooklm-mcp-cli..." -ForegroundColor White

    $installer = $null
    if (Get-Command uv   -ErrorAction SilentlyContinue) { $installer = "uv" }
    elseif (Get-Command pipx -ErrorAction SilentlyContinue) { $installer = "pipx" }
    elseif (Get-Command pip  -ErrorAction SilentlyContinue) { $installer = "pip" }

    if (-not $installer) {
        Write-Fail "No se encontro uv, pipx ni pip. Instala uno de ellos primero."
        Write-Host "   Recomendado: https://docs.astral.sh/uv/getting-started/installation/" -ForegroundColor Gray
        exit 1
    }

    Write-Host "   Usando: $installer" -ForegroundColor Gray
    # pip escribe a stderr aunque tenga exito; desactivar Stop temporalmente
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    if ($installer -eq "uv")        { & uv tool install notebooklm-mcp-cli }
    elseif ($installer -eq "pipx")  { & pipx install notebooklm-mcp-cli }
    else                            { & pip install notebooklm-mcp-cli }
    $ErrorActionPreference = $prevPref

    # Refrescar PATH (incluir directorio de scripts de usuario de pip si aplica)
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH    = "$machinePath;$userPath"

    # pip con --user instala en AppData\Roaming\Python\PythonXXX\Scripts (fuera del PATH tipico)
    if ($installer -eq "pip") {
        $pipUserScripts = & python -c "import sysconfig; print(sysconfig.get_path('scripts', 'nt_user'))" 2>$null
        if ($pipUserScripts -and (Test-Path $pipUserScripts)) {
            $env:PATH = "$env:PATH;$pipUserScripts"
        }
    }

    $mcpCmd = Get-Command notebooklm-mcp -ErrorAction SilentlyContinue
    $mcpBin = if ($mcpCmd) { $mcpCmd.Source } else { $null }

    if (-not $mcpBin) {
        Write-Fail "notebooklm-mcp no encontrado despues de instalar. Verifica tu PATH."
        exit 1
    }
    Write-Ok "Instalado: $mcpBin"
}

# --- 3. Copiar skill al proyecto target ---
Write-Step "Instalando skill /research--notebooklm"

$skillSrc = Join-Path $ScriptDir "skill.md"
$skillDir = Join-Path $TargetProject ".claude\skills"
$skillDst = Join-Path $skillDir "research--notebooklm.md"

if (-not (Test-Path $skillDir)) {
    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
}

Copy-Item -Path $skillSrc -Destination $skillDst -Force
Write-Ok "Skill copiado a: $skillDst"

# --- 4. Inyectar snippet en CLAUDE.md del proyecto target ---
Write-Step "Actualizando CLAUDE.md del proyecto"

$snippetFile = Join-Path $ScriptDir "claude-snippet.md"
$claudeMd    = Join-Path $TargetProject "CLAUDE.md"

if (Test-Path $claudeMd) {
    $existingContent = Get-Content $claudeMd -Raw
    if ($existingContent -match "NotebookLM") {
        Write-Warn "CLAUDE.md ya menciona NotebookLM — no se modifico"
    } else {
        $snippet = Get-Content $snippetFile -Raw
        "`n$snippet" | Out-File -FilePath $claudeMd -Append -Encoding utf8
        Write-Ok "Snippet agregado a: $claudeMd"
    }
} else {
    Write-Warn "No hay CLAUDE.md en el proyecto — crealo si quieres que Claude conozca el modulo"
}

# --- 5. Agregar MCP a .claude/settings.json del proyecto target ---
Write-Step "Configurando MCP en el proyecto"

$settingsDir  = Join-Path $TargetProject ".claude"
$settingsFile = Join-Path $settingsDir "settings.json"

if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

if (Test-Path $settingsFile) {
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
} else {
    $settings = [PSCustomObject]@{}
}

if (-not ($settings.PSObject.Properties.Name -contains "mcpServers")) {
    $settings | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
}

if (-not ($settings.mcpServers.PSObject.Properties.Name -contains "notebooklm")) {
    $mcpEntry = [PSCustomObject]@{ command = $mcpBin }
    $settings.mcpServers | Add-Member -MemberType NoteProperty -Name "notebooklm" -Value $mcpEntry
    Write-Ok "MCP agregado con comando: $mcpBin"
} else {
    Write-Warn "MCP 'notebooklm' ya existe en settings.json — no se modifico"
}

$settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
Write-Ok "Settings guardado: $settingsFile"

# --- 6. Verificar autenticacion ---
Write-Step "Verificando autenticacion con NotebookLM"

$authOk = $false
try {
    $nlmCmd = Get-Command nlm -ErrorAction SilentlyContinue
    if ($nlmCmd) {
        $null = & nlm profile list 2>&1
        if ($LASTEXITCODE -eq 0) { $authOk = $true }
    }
} catch {
    $authOk = $false
}

if ($authOk) {
    Write-Ok "Autenticacion encontrada"
} else {
    Write-Warn "No hay sesion activa. Ejecuta: nlm login"
    Write-Host "   (Abre Chrome y pide login con tu cuenta Google)" -ForegroundColor Gray
}

# --- 7. Resumen final ---
Write-Host ""
Write-Host "-----------------------------------------" -ForegroundColor DarkGray
Write-Host " Modulo NotebookLM instalado correctamente" -ForegroundColor Green
Write-Host "-----------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host " Proyecto: $TargetProject"
Write-Host " Skill:    $skillDst"
Write-Host " Settings: $settingsFile"
Write-Host ""
if (-not $authOk) {
    Write-Host " PENDIENTE: Ejecuta 'nlm login' para autenticarte" -ForegroundColor Yellow
    Write-Host ""
}
Write-Host " Uso en Claude Code:" -ForegroundColor White
Write-Host "   /research--notebooklm             -> inicia el asistente de research"
Write-Host "   /research--notebooklm listar      -> muestra tus cuadernos"
Write-Host "   /research--notebooklm consultar   -> pregunta a un cuaderno con citas"
Write-Host ""
Write-Host " Documentacion completa de herramientas: nlm --ai"
Write-Host ""
