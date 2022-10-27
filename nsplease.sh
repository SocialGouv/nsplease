#! /usr/bin/env sh

info() {
  printf "[INFO]\t%s\n" "$*"
}

out() {
  "$@" | while read -r line; do
    printf "[EXEC]\t%s\n" "$line"
  done
}

main() {
  info "waiting for 'nsplease/project' labelled namespaces..."

  # watch namespace creations, only ADDED type and labelled with nsplease/project
  kubectl get namespace --watch --output-watch-events -o json |
    jq --unbuffered --raw-output \
      'if (.object.metadata.labels | has("nsplease/project"))
       and .type == "ADDED" then
        [.object.metadata.name, .object.metadata.labels."nsplease/project"] | @tsv
       else empty
       end' |
    while read -r NAMESPACE PROJECT; do
      info "got labelled namespace: $NAMESPACE $PROJECT"

      # create privileged role in requested namespace
      out kubectl create role nsplease-role \
        --namespace="$NAMESPACE" \
        --verb="*" \
        --resource="*"

      # give rights on namespace to project's ServiceAccount
      out kubectl create rolebinding "nsplease-rb-$PROJECT-$NAMESPACE" \
        --namespace="$NAMESPACE" \
        --role=nsplease-role \
        --serviceaccount="$PROJECT:nsplease-sa"

      # remove label to avoid doing this again for the same namespace
      out kubectl label namespace "$NAMESPACE" nsplease/project-
    done
}

main
