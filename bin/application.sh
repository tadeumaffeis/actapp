#!/usr/bin/env bash

set -euo pipefail

unset GNOME_TERMINAL_SCREEN
unset GNOME_TERMINAL_SERVICE
unset VTE_VERSION

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

JDK_VERSION="25.0.2"
JDK_DIR_NAME="jdk-${JDK_VERSION}"
JDK_ARCHIVE="jdk-25_linux-x64_bin.tar.gz"
JDK_URL="https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.tar.gz"
JDK_TARGET_DIR="$(cd .. && pwd)/${JDK_DIR_NAME}"

LIB_DIR="$(cd .. && pwd)/lib"
LOG_DIR="$(cd .. && pwd)/logs"
PID_FILE="$LOG_DIR/activitiesapplication.pid"
STDOUT_LOG="$LOG_DIR/log"
STDERR_LOG="$LOG_DIR/log.err"
MAIN_CLASS="br.gov.sp.fatec.itu.aa.main.ActivitiesApplication"

cleanup_temp() {
  rm -f "$SCRIPT_DIR"/database-* 2>/dev/null || true
}

fail() {
  echo "Erro: $1" >&2
  cleanup_temp
  exit 1
}

check_dependencies() {
  local deps=(wget tar nohup)
  for cmd in "${deps[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || fail "dependência não encontrada: $cmd"
  done
}

download_jdk() {
  echo "Baixando JDK 25..."
  wget -c "$JDK_URL" -O "$JDK_ARCHIVE" || fail "falha no download do JDK"
}

extract_jdk() {
  echo "Descompactando JDK 25..."
  tar -xzf "$JDK_ARCHIVE" || fail "falha ao descompactar o JDK"
}

install_jdk() {
  if [ -d "$JDK_TARGET_DIR" ]; then
    echo "JDK já encontrado em: $JDK_TARGET_DIR"
    return
  fi

  download_jdk
  extract_jdk

  [ -d "$SCRIPT_DIR/$JDK_DIR_NAME" ] || fail "diretório extraído do JDK não encontrado"

  mv "$SCRIPT_DIR/$JDK_DIR_NAME" "$(dirname "$JDK_TARGET_DIR")/" || fail "falha ao mover o JDK"
  rm -f "$JDK_ARCHIVE"
}

build_classpath() {
  [ -d "$LIB_DIR" ] || fail "diretório lib não encontrado: $LIB_DIR"

  shopt -s nullglob
  local jars=("$LIB_DIR"/*.jar)
  shopt -u nullglob

  [ ${#jars[@]} -gt 0 ] || fail "nenhum arquivo .jar encontrado em $LIB_DIR"

  local cp=""
  local jar
  for jar in "${jars[@]}"; do
    jar="$(readlink -f "$jar")"
    if [ -z "$cp" ]; then
      cp="$jar"
    else
      cp="${cp}:$jar"
    fi
  done

  printf '%s\n' "$cp"
}

start_application() {
  mkdir -p "$LOG_DIR"

  export JAVA_HOME="$JDK_TARGET_DIR"
  export PATH="$JAVA_HOME/bin:$PATH"

  command -v java >/dev/null 2>&1 || fail "java não encontrado mesmo após configurar JAVA_HOME"

  local classpath
  classpath="$(build_classpath)"

  echo "*************************************"
  echo "* Status: Java 25 found!            *"
  echo "* Action: Starting application...   *"
  echo "*************************************"
  echo "JAVA_HOME=$JAVA_HOME"
  echo "CLASSPATH=$classpath"

  nohup java -cp "$classpath" "$MAIN_CLASS" \
    1>>"$STDOUT_LOG" \
    2>>"$STDERR_LOG" &

  local pid=$!
  echo "$pid" > "$PID_FILE"

  echo "Aplicação iniciada com PID $pid"
  echo "PID salvo em $PID_FILE"
  echo "Saída padrão: $STDOUT_LOG"
  echo "Saída de erro: $STDERR_LOG"
}

stop_application() {
  if [ ! -f "$PID_FILE" ]; then
    fail "arquivo PID não encontrado: $PID_FILE"
  fi

  local pid
  pid="$(cat "$PID_FILE")"

  if kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" || fail "não foi possível encerrar o processo $pid"
    rm -f "$PID_FILE"
    echo "Aplicação encerrada. PID $pid"
  else
    rm -f "$PID_FILE"
    fail "processo $pid não está em execução"
  fi
}

status_application() {
  if [ ! -f "$PID_FILE" ]; then
    echo "Aplicação não está em execução."
    return 1
  fi

  local pid
  pid="$(cat "$PID_FILE")"

  if kill -0 "$pid" >/dev/null 2>&1; then
    echo "Aplicação em execução. PID $pid"
    return 0
  else
    echo "Arquivo PID existe, mas o processo $pid não está ativo."
    return 1
  fi
}

main() {
  check_dependencies

  case "${1:-start}" in
    start)
      install_jdk
      start_application
      ;;
    stop)
      stop_application
      ;;
    restart)
      if status_application >/dev/null 2>&1; then
        stop_application
      fi
      install_jdk
      start_application
      ;;
    status)
      status_application
      ;;
    *)
      echo "Uso: $0 {start|stop|restart|status}"
      exit 1
      ;;
  esac

  cleanup_temp
}

main "$@"

