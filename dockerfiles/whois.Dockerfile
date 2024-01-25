FROM alpine:3.15

RUN apk add --no-cache whois

ENTRYPOINT ["/bin/sh"]