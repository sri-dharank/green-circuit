#!/bin/sh
set -e

URL="${SPRING_DATASOURCE_URL:-$DATABASE_URL}"

if [ -n "$URL" ]; then
  case "$URL" in
    postgres://*|postgresql://*)
      WITHOUT_SCHEME="${URL#*://}"
      if echo "$WITHOUT_SCHEME" | grep -q "@"; then
        CREDENTIALS="${WITHOUT_SCHEME%@*}"
        HOST_AND_DB="${WITHOUT_SCHEME##*@}"
        USER="${CREDENTIALS%%:*}"
        PASS="${CREDENTIALS#*:}"
      else
        HOST_AND_DB="$WITHOUT_SCHEME"
        USER=""
        PASS=""
      fi

      HOST="${HOST_AND_DB%%/*}"
      DB="${HOST_AND_DB#*/}"
      if ! echo "$HOST" | grep -q ":"; then
        HOST="$HOST:5432"
      fi

      if echo "$HOST" | grep -q "render.com"; then
        if ! echo "$DB" | grep -q "sslmode"; then
          if echo "$DB" | grep -q "?"; then
            DB="$DB&sslmode=require"
          else
            DB="$DB?sslmode=require"
          fi
        fi
      fi

      export SPRING_DATASOURCE_URL="jdbc:postgresql://$HOST/$DB"
      
      if [ -n "$USER" ]; then
        export SPRING_DATASOURCE_USERNAME="$USER"
      fi
      if [ -n "$PASS" ]; then
        export SPRING_DATASOURCE_PASSWORD="$PASS"
      fi

      export SPRING_DATASOURCE_DRIVER_CLASS_NAME="org.postgresql.Driver"
      export SPRING_JPA_DATABASE_PLATFORM="org.hibernate.dialect.PostgreSQLDialect"
      export SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT="org.hibernate.dialect.PostgreSQLDialect"

      echo "[entrypoint] Prepared PostgreSQL datasource: $SPRING_DATASOURCE_URL"
      echo "[entrypoint] Database user: $SPRING_DATASOURCE_USERNAME"
      ;;
  esac
fi

exec java \
  ${SPRING_DATASOURCE_URL:+-Dspring.datasource.url="$SPRING_DATASOURCE_URL"} \
  ${SPRING_DATASOURCE_USERNAME:+-Dspring.datasource.username="$SPRING_DATASOURCE_USERNAME"} \
  ${SPRING_DATASOURCE_PASSWORD:+-Dspring.datasource.password="$SPRING_DATASOURCE_PASSWORD"} \
  ${SPRING_DATASOURCE_DRIVER_CLASS_NAME:+-Dspring.datasource.driver-class-name="$SPRING_DATASOURCE_DRIVER_CLASS_NAME"} \
  ${SPRING_JPA_DATABASE_PLATFORM:+-Dspring.jpa.database-platform="$SPRING_JPA_DATABASE_PLATFORM"} \
  ${SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT:+-Dspring.jpa.properties.hibernate.dialect="$SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT"} \
  -jar app.jar "$@"
