#!/bin/sh

while ! nc -z postgres 5432; do
  sleep 1
done

while ! nc -z elasticsearch 9200; do
  sleep 1
done

exec "$@"
