FROM alpine:3.16

RUN apk update && \
    apk --no-cache add curl jq

# Kubectl
RUN curl -sL https://dl.k8s.io/release/v1.25.3/bin/linux/amd64/kubectl > /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

WORKDIR /home/app
COPY nsplease.sh .
RUN chmod +x nsplease.sh
CMD ["./nsplease.sh"]
