#!/usr/bin/env bash

# ==============================================================================
#  ActApp Update Script
#  Finalidade:
#    - Clonar temporariamente o repositório actapp
#    - Copiar os arquivos .jar da pasta lib para o diretório local de libs
#    - Remover arquivos temporários ao final
# ==============================================================================

set -o errexit
set -o nounset
set -o pipefail

# ------------------------------------------------------------------------------
# Configuração
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/tadeumaffeis/actapp.git"

TMP_DIR="${SCRIPT_DIR}/../tmp"
REPO_DIR="${TMP_DIR}/actapp"
SOURCE_LIB_DIR="${REPO_DIR}/lib"
TARGET_LIB_DIR="${SCRIPT_DIR}/../lib"

# ------------------------------------------------------------------------------
# Utilitários
# ------------------------------------------------------------------------------
log_info() {
    printf '[INFO] %s\n' "$1"
}

log_error() {
    printf '[ERROR] %s\n' "$1" >&2
}

cleanup() {
    if [[ -d "${TMP_DIR}" ]]; then
        log_info "Removendo diretório temporário: ${TMP_DIR}"
        rm -rf "${TMP_DIR}"
    fi
}

abort() {
    log_error "$1"
    exit 1
}

require_command() {
    local cmd="$1"
    command -v "${cmd}" >/dev/null 2>&1 || abort "Dependência não encontrada: ${cmd}"
}

pause_if_interactive() {
    if [[ -t 0 && -t 1 ]]; then
        read -r -p "Pressione ENTER para finalizar..."
    fi
}

trap cleanup EXIT

# ------------------------------------------------------------------------------
# Validação de dependências
# ------------------------------------------------------------------------------
require_command git
require_command cp
require_command rm
require_command mkdir
require_command find

# ------------------------------------------------------------------------------
# Preparação do diretório temporário
# ------------------------------------------------------------------------------
if [[ ! -d "${TMP_DIR}" ]]; then
    log_info "Criando diretório temporário: ${TMP_DIR}"
    mkdir -p "${TMP_DIR}"
fi

# ------------------------------------------------------------------------------
# Remoção do clone anterior
# ------------------------------------------------------------------------------
if [[ -d "${REPO_DIR}" ]]; then
    log_info "Removendo repositório temporário anterior..."
    rm -rf "${REPO_DIR}"
fi

# ------------------------------------------------------------------------------
# Clonagem do repositório
# ------------------------------------------------------------------------------
log_info "Clonando repositório actapp..."
git clone "${REPO_URL}" "${REPO_DIR}"

[[ -d "${REPO_DIR}" ]] || abort "O diretório do repositório não foi criado após o clone."

# ------------------------------------------------------------------------------
# Validação da pasta de bibliotecas
# ------------------------------------------------------------------------------
[[ -d "${SOURCE_LIB_DIR}" ]] || abort "Pasta de bibliotecas não encontrada: ${SOURCE_LIB_DIR}"

if ! find "${SOURCE_LIB_DIR}" -maxdepth 1 -type f -name '*.jar' | grep -q .; then
    abort "Nenhum arquivo .jar encontrado em ${SOURCE_LIB_DIR}"
fi

# ------------------------------------------------------------------------------
# Garantia da pasta de destino
# ------------------------------------------------------------------------------
if [[ ! -d "${TARGET_LIB_DIR}" ]]; then
    log_info "Criando diretório de destino: ${TARGET_LIB_DIR}"
    mkdir -p "${TARGET_LIB_DIR}"
fi

# ------------------------------------------------------------------------------
# Cópia dos arquivos .jar
# ------------------------------------------------------------------------------
log_info "Copiando arquivos .jar para ${TARGET_LIB_DIR}..."
find "${SOURCE_LIB_DIR}" -maxdepth 1 -type f -name '*.jar' -exec cp -f {} "${TARGET_LIB_DIR}/" \;

# ------------------------------------------------------------------------------
# Finalização
# ------------------------------------------------------------------------------
log_info "Atualização concluída com sucesso."
pause_if_interactive
exit 0
