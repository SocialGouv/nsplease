#! /usr/bin/env sh

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
  info "waiting for 'nsplease/project' labelled namespaces..."
  kubectl get namespace --watch --output-watch-events -o json |
    jq --unbuffered --raw-output \
      'if (.object.metadata.labels | has("nsplease/project"))
       and .type == "ADDED" then
        [.object.metadata.name, .object.metadata.labels."nsplease/project"] | @tsv
       else empty
       end' |
    while read -r NAME LABEL; do
      debug "got labelled namespace: $NAME $LABEL"
    done
}

main
