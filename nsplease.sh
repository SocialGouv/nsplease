#! /usr/bin/env sh

out() {
  "$@" | while read -r line; do
    printf "[EXEC]\t%s\n" "$line"
  done
}

main() {
  echo "waiting for 'nsplease/project' labelled namespaces..."
  kubectl get namespace --watch --output-watch-events -o json |
    jq --unbuffered --raw-output \
      'if (.object.metadata.labels | has("nsplease/project"))
       and .type == "ADDED" then
        [.object.metadata.name, .object.metadata.labels."nsplease/project"] | @tsv
       else empty
       end' |
    while read -r NAMESPACE PROJECT; do
      echo "got labelled namespace: $NAMESPACE $PROJECT"

      out kubectl create clusterrolebinding "nsplease-crb-$PROJECT-$NAMESPACE" \
        --clusterrole=cluster-admin \
        --serviceaccount="$PROJECT:nsplease-sa"

      out kubectl label namespace "$NAMESPACE" nsplease/project-
    done
}

main
