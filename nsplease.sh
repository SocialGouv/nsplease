#!/usr/bin/env sh

# config
CREATE_SA="${CREATE_SA:-true}"
NSPLEASE_SERVICEACCOUNT_NAME="${NSPLEASE_SERVICEACCOUNT_NAME:-nsplease-sa}"
NSPLEASE_ROLEBINDING_NAME="${NSPLEASE_ROLEBINDING_NAME:-nsplease-rb}"
NSPLEASE_ROLE_NAME="${NSPLEASE_ROLE_NAME:-nsplease-role}"

info() {
  printf "[INFO]\t%s\n" "$*"
}

out() {
  "$@" | while read -r line; do
    printf "[EXEC]\t%s\n" "$line"
  done
}

create_resources() { (
  # exit function if any command fails
  set -e

  # create ServiceAccount in CI Namespace
  if [ "$CREATE_SA" = true ]; then
    out kubectl create serviceaccount "$NSPLEASE_SERVICEACCOUNT_NAME" \
      --namespace="$CI_NAMESPACE"
  else
    if ! kubectl get "$NSPLEASE_SERVICEACCOUNT_NAME" \
      --namespace "$CI_NAMESPACE"; then
      info "ServiceAccount $NSPLEASE_SERVICEACCOUNT_NAME not found in CI Namespace $CI_NAMESPACE and CREATE_SA not set to true, aborting"
      return 1
    fi
  fi

  # create privileged Role in requested Namespace
  out kubectl create role "$NSPLEASE_ROLE_NAME" \
    --namespace="$REQUESTED_NAMESPACE" \
    --verb="*" \
    --resource="*"

  # give rights on requested Namespace to project's CI ServiceAccount
  out kubectl create rolebinding "$NSPLEASE_ROLEBINDING_NAME-$CI_NAMESPACE" \
    --namespace="$REQUESTED_NAMESPACE" \
    --role="$NSPLEASE_ROLE_NAME" \
    --serviceaccount="$CI_NAMESPACE:$NSPLEASE_SERVICEACCOUNT_NAME"

  # create privileged Role in CI Namespace
  out kubectl create role "$NSPLEASE_ROLE_NAME" \
    --namespace="$CI_NAMESPACE" \
    --verb="*" \
    --resource="*"

  # give rights on CI Namespace to project's CI ServiceAccount
  out kubectl create rolebinding "$NSPLEASE_ROLEBINDING_NAME" \
    --namespace="$CI_NAMESPACE" \
    --role="$NSPLEASE_ROLE_NAME" \
    --serviceaccount="$CI_NAMESPACE:$NSPLEASE_SERVICEACCOUNT_NAME"
); }

main() {
  info "waiting for namespaces with label 'nsplease/done=false'..."

  # watch namespace creations, only ADDED type and labeled with nsplease/project
  kubectl get namespace --watch --output-watch-events -o json |
    jq --unbuffered --raw-output \
      'if (.object.metadata.labels | has("nsplease/project"))
       and (.object.metadata.labels."nsplease/done" == "false")
       and (.type == "ADDED") then
        [.object.metadata.name, .object.metadata.labels."nsplease/project"] | @tsv
       else empty
       end' |
    while read -r REQUESTED_NAMESPACE PROJECT; do
      info "got labeled namespace: $REQUESTED_NAMESPACE $PROJECT"

      # get the CI Namespace according to the convention
      CI_NAMESPACE="$PROJECT-ci"

      if create_resources; then
        # remove label to avoid doing this again for the same namespace
        out kubectl label namespace --overwrite "$NAMESPACE" nsplease/done=true
      else
        info "todo retry"
      fi

    done
}

main
