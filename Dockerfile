FROM node:lts-alpine3.12 AS build
LABEL frontend_app="0.0.1"

WORKDIR /opt/frontend

RUN apk --verbose --update-cache --upgrade add \
    git \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && sed -i "s/conduit.productionready.io\\/api/backend.okurnitsov.test.coherentprojects.net/g" src/agent.js \
    && npm install \
    && npm run build 

FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html
ENV BUILD_PATH=/opt/frontend/devops-training-project-frontend/build 
COPY --chown=0:0 --from=build ${BUILD_PATH} ${WORKDIR}
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
EXPOSE 80
CMD [ "nginx", "-g", "daemon off;" ]