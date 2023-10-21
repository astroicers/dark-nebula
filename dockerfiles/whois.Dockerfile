FROM alpine:3.15

RUN apk add whois

ENTRYPOINT ["whois"]