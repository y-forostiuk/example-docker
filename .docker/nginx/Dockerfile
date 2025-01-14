FROM nginx:1.27.3-alpine

ARG USER_ID
ARG GROUP_ID
ARG USER_NAME
ARG GROUP_NAME
ARG PHP_PORT
ARG PHP_HOST
ARG NODE_HOST
ARG NODE_PORT
ARG PHPMYADMIN_HOST
ARG PHPMYADMIN_PORT
ARG SERVER_PORT
ARG HOST_NAME

ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV USER_NAME=${USER_NAME}
ENV GROUP_NAME=${GROUP_NAME}
ENV PHP_PORT=${PHP_PORT}
ENV PHP_HOST=${PHP_HOST}
ENV NODE_HOST=${NODE_HOST}
ENV NODE_PORT=${NODE_PORT}
ENV PHPMYADMIN_HOST=${PHPMYADMIN_HOST}
ENV PHPMYADMIN_PORT=${PHPMYADMIN_PORT}
ENV SERVER_PORT=${SERVER_PORT}
ENV HOST_NAME=${HOST_NAME}

RUN apk update
RUN apk add --no-cache gettext openssl

RUN delgroup dialout

RUN addgroup -g ${GROUP_ID} --system ${GROUP_NAME}
RUN adduser -G ${GROUP_NAME} --system -D --shell /bin/sh -u ${USER_ID} ${USER_NAME}

RUN sed -i "s/user  nginx/user ${GROUP_NAME}/g" /etc/nginx/nginx.conf

COPY ./default.conf.template /etc/nginx/templates/default.conf.template
RUN envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

COPY ./nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www/html /etc/nginx/certs/

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/nginx-selfsigned.key \
    -out /etc/nginx/certs/nginx-selfsigned.crt \
    -subj "/C=UA/ST=Kyiv/L=Kyiv/O=Company/OU=ITDepartment/CN=localhost"

RUN openssl dhparam -out /etc/nginx/dhparam.pem 2048

RUN chmod 644 /etc/nginx/certs/nginx-selfsigned.key /etc/nginx/certs/nginx-selfsigned.crt /etc/nginx/dhparam.pem

#RUN ls -la /etc/nginx/certs/ && tail -f /dev/null

# Assign permissions of the working directory
WORKDIR /var/www/html
RUN chmod -R 777 .
RUN chown -R ${USER_NAME}:${GROUP_NAME} .

CMD ["nginx", "-g", "daemon off;"]

EXPOSE ${SERVER_PORT}
