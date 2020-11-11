FROM node:lts-alpine3.12 AS build
LABEL frontend_app="0.0.1"

ARG BACKEND_URL=dummy.url
WORKDIR /opt/frontend

RUN apk --verbose --update-cache --upgrade add \
    git \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* 
COPY --chown=0:0 . .    
RUN sed -i "s/conduit.productionready.io\\/api/${BACKEND_URL}/g" src/agent.js \
    && npm install \
    && npm run build 

FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html
ENV BUILD_PATH=/opt/frontend/build 
COPY --chown=0:0 --from=build ${BUILD_PATH} ${WORKDIR}
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
EXPOSE 80
CMD [ "nginx", "-g", "daemon off;" ]
