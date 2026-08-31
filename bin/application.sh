#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================================
# Activities Application Launcher
# Finalidade:
#   - Garantir a presença do JDK local
#   - Montar o classpath automaticamente
#   - Iniciar a aplicação Java com logs
# ============================================================================

# ----------------------------------------------------------------------------
# Funções
# ----------------------------------------------------------------------------
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

fail() {
    log_error "Execução finalizada com erro."
    cleanup
    exit 1
}

cleanup() {
    rm -f database-* 2>/dev/null || true
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Dependência não encontrada no PATH: $cmd"
        return 1
    fi
}

download_jdk() {
    log_info "Baixando JDK de: ${JDK_DOWNLOAD_URL}"

    if command -v wget >/dev/null 2>&1; then
        wget -c "${JDK_DOWNLOAD_URL}" -O "${JDK_ARCHIVE_NAME}" || {
            log_error "Erro no download do JDK."
            rm -f "${JDK_ARCHIVE_NAME}" 2>/dev/null || true
            return 1
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -L -C - -o "${JDK_ARCHIVE_NAME}" "${JDK_DOWNLOAD_URL}" || {
            log_error "Erro no download do JDK."
            rm -f "${JDK_ARCHIVE_NAME}" 2>/dev/null || true
            return 1
        }
    else
        log_error "Dependência não encontrada: wget ou curl"
        return 1
    fi
}

extract_jdk() {
    log_info "Descompactando ${JDK_ARCHIVE_NAME}..."

    case "${JDK_ARCHIVE_NAME}" in
        *.tar.gz|*.tgz)
            tar -xzf "${JDK_ARCHIVE_NAME}" || {
                log_error "Erro ao descompactar o JDK."
                return 1
            }
            ;;
        *.zip)
            require_command unzip || return 1
            unzip -q "${JDK_ARCHIVE_NAME}" || {
                log_error "Erro ao descompactar o JDK."
                return 1
            }
            ;;
        *)
            log_error "Formato de arquivo JDK não suportado: ${JDK_ARCHIVE_NAME}"
            return 1
            ;;
    esac
}

install_jdk() {
    log_info "Instalando JDK em ${JDK_TARGET_DIR}..."

    rm -rf "${JDK_TARGET_DIR}" 2>/dev/null || true

    if [[ ! -d "${JDK_FOLDER_NAME}" ]]; then
        log_error "Pasta extraída não encontrada: ${JDK_FOLDER_NAME}"
        return 1
    fi

    mv "${JDK_FOLDER_NAME}" ".." || {
        log_error "Erro ao mover o JDK para o diretório de destino."
        return 1
    }

    rm -f "${JDK_ARCHIVE_NAME}" 2>/dev/null || true
}

# ----------------------------------------------------------------------------
# Configurações gerais
# ----------------------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" || exit 1
trap cleanup EXIT

APP_NAME="ActivitiesApplication"
MAIN_CLASS="br.gov.sp.fatec.itu.aa.main.ActivitiesApplication"

JDK_VERSION="25.0.4.1"
JDK_FOLDER_NAME="jdk-${JDK_VERSION}"

# Oracle JDK para Linux x64. No Windows o .bat usa jdk-25_windows-x64_bin.zip.
JDK_ARCHIVE_NAME="jdk-25_linux-x64_bin.tar.gz"
JDK_DOWNLOAD_URL="https://download.oracle.com/java/25/latest/${JDK_ARCHIVE_NAME}"

JDK_TARGET_DIR="../${JDK_FOLDER_NAME}"
LIB_DIR="../lib"
LOG_DIR="../logs"

# ----------------------------------------------------------------------------
# Garantia do JDK local
# ----------------------------------------------------------------------------
if [[ -d "${JDK_TARGET_DIR}" ]]; then
    log_info "JDK ${JDK_VERSION} localizado em ${JDK_TARGET_DIR}."
else
    log_info "JDK ${JDK_VERSION} não encontrado. Iniciando download..."
    download_jdk || fail
    extract_jdk || fail
    install_jdk || fail
fi

# ----------------------------------------------------------------------------
# Configuração do ambiente Java
# ----------------------------------------------------------------------------
JAVA_HOME="$(cd "${JDK_TARGET_DIR}" && pwd)"
export JAVA_HOME
export PATH="${JAVA_HOME}/bin:${PATH}"

if [[ ! -x "${JAVA_HOME}/bin/java" ]]; then
    log_error "java não encontrado ou sem permissão de execução em ${JAVA_HOME}/bin"
    fail
fi

# ----------------------------------------------------------------------------
# Garantia da pasta de logs
# ----------------------------------------------------------------------------
mkdir -p "${LOG_DIR}" || fail

# ----------------------------------------------------------------------------
# Montagem dinâmica do CLASSPATH
# ----------------------------------------------------------------------------
if [[ ! -d "${LIB_DIR}" ]]; then
    log_error "Diretório de bibliotecas não encontrado: ${LIB_DIR}"
    fail
fi

CLASSPATH=""
shopt -s nullglob
jar_files=("${LIB_DIR}"/*.jar)
shopt -u nullglob

if (( ${#jar_files[@]} == 0 )); then
    log_error "Nenhum arquivo .jar encontrado em ${LIB_DIR}"
    fail
fi

for jar in "${jar_files[@]}"; do
    jar_abs="$(cd "$(dirname "$jar")" && pwd)/$(basename "$jar")"
    if [[ -n "${CLASSPATH}" ]]; then
        CLASSPATH="${CLASSPATH}:${jar_abs}"
    else
        CLASSPATH="${jar_abs}"
    fi
done

log_info "Inicializando ${APP_NAME}..."
log_info "JAVA_HOME=${JAVA_HOME}"

# ----------------------------------------------------------------------------
# Execução da aplicação
# ----------------------------------------------------------------------------
"${JAVA_HOME}/bin/java" -cp "${CLASSPATH}" "${MAIN_CLASS}" \
    >> "${LOG_DIR}/log" \
    2>> "${LOG_DIR}/log.err" &

pid=$!

if ! kill -0 "${pid}" >/dev/null 2>&1; then
    log_error "Falha ao iniciar a aplicação."
    fail
fi

log_info "Aplicação iniciada com sucesso. PID=${pid}"
