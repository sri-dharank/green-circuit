#!/bin/sh
set -e

URL="${SPRING_DATASOURCE_URL:-$DATABASE_URL}"

if [ -n "$URL" ]; then
  case "$URL" in
    postgres://*|postgresql://*)
      CLEAN_URL=$(echo "$URL" | sed -E 's|^(postgres(ql)?://)[^@]+@|\1|' | sed -E 's|^(postgres(ql)?):|jdbc:postgresql:|')
      export SPRING_DATASOURCE_URL="$CLEAN_URL"
      
      if [ -z "$SPRING_DATASOURCE_USERNAME" ]; then
        EXTRACTED_USER=$(echo "$URL" | sed -E -n 's|^(postgres(ql)?://)([^:@]+)(:.*)?@.*|\3|p')
        if [ -n "$EXTRACTED_USER" ]; then
          export SPRING_DATASOURCE_USERNAME="$EXTRACTED_USER"
        fi
      fi
      
      if [ -z "$SPRING_DATASOURCE_PASSWORD" ]; then
        EXTRACTED_PASS=$(echo "$URL" | sed -E -n 's|^(postgres(ql)?://)[^:@]+:([^@]+)@.*|\3|p')
        if [ -n "$EXTRACTED_PASS" ]; then
          export SPRING_DATASOURCE_PASSWORD="$EXTRACTED_PASS"
        fi
      fi
      echo "[entrypoint] Successfully prepared datasource URL: $SPRING_DATASOURCE_URL"
      ;;
  esac
fi

exec java -jar app.jar "$@"
