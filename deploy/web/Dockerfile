# CI builds Flutter once; this runtime contains only the public web artifact.
FROM nginx:1.28-alpine
COPY deploy/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web/ /usr/share/nginx/html/
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
