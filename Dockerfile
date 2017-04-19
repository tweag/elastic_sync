FROM nebo15/alpine-elixir:1.4.2

WORKDIR /app

RUN apk add --no-cache curl

COPY mix.exs mix.lock /app/
RUN mix deps.get

COPY . /app/
RUN mix compile
