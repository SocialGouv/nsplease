#! /bin/sh

debug() {
  printf "[DEBUG]\t%s\n" "$*"
}

info() {
  printf "[INFO]\t%s\n" "$*"
}

warn() {
  printf "[WARN]\t%s\n" "$*"
}

out() {
  "$@" | while read -r line; do
    printf "[EXEC]\t%s\n" "$line"
  done
}

main() {
  info "waiting for labelled namespaces..."
  kubectl get namespace --watch --output-watch-events -o json |
    jq --unbuffered --raw-output \
      'if .object.metadata.labels | has("nsplease/project") then
        [.type, .object.metadata.name, .object.metadata.labels."nsplease/project"]
          | select(.[0] == "ADDED")
          | @tsv
        else empty
        end' |
    while read -r TYPE NAME LABEL; do
      debug "got event: $TYPE $NAME $LABEL"
    done
}

main
