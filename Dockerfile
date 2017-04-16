FROM nebo15/alpine-elixir:1.4.2

WORKDIR /app

COPY mix.exs mix.lock /app/
RUN mix deps.get

COPY . /app/
RUN mix compile
