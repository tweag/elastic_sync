FROM nebo15/alpine-elixir:1.4.2

WORKDIR /app

RUN mix local.hex --force
RUN mix local.rebar --force
RUN apk --no-cache add inotify-tools

CMD ["mix", "test"]
