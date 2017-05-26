# ElasticSync

[![Build Status](https://travis-ci.org/promptworks/elastic_sync.svg?branch=master)](https://travis-ci.org/promptworks/elastic_sync)

This project is in its infancy. So unless you're interested in contributing, you should probably move along.

This project is inspired by [searchkick](https://github.com/ankane/searchkick). It aims to provide:

+ An Ecto-like interface for creating/updating/deleting ElasticSearch documents.
+ An seamless way to keep your Ecto models in synchronization with an ElasticSearch.
+ Mix tasks for reindexing.

It is definitely *not* an Ecto adapter for ElasticSearch.

## Installation

This project is not currently available on Hex, so for now, you'll have to load it from GitHub.

  1. Add `elastic_sync` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:elastic_sync, github: "promptworks/elastic_sync"}]
end
```

  2. Ensure `elastic_sync` is started before your application:

```elixir
def application do
  [applications: [:elastic_sync]]
end
```

## Usage

### ElasticSync.Index

Like Ecto, ElasticSync has a concept of a schema and a repo. Here's how you'd configure your schema:

```elixir
defmodule MyApp.Food do
  defstruct [:id, :name]

  use ElasticSync.Index, index: "foods"

  @doc """
  Convert a struct to a plain ol' map. This will become our document.
  """
  def to_search_document(record) do
    Map.take(record, [:id, :name])
  end
end
```

Great. Now, you can insert/update/delete some data.

```elixir
alias MyApp.Food
alias ElasticSync.Repo

{:ok, 201, _response} = Repo.insert(%Food{id: 1})
{:ok, 200, _response} = Repo.update(%Food{id: 1, name: "meatloaf"})
{:ok, 200, _response} = Repo.delete(%Food{id: 1})

{:ok, 200, _response} = Repo.insert_all(Food, [
  %Food{id: 1, name: "cheesecake"},
  %Food{id: 2, name: "applesauce"},
  %Food{id: 3, name: "sausage"}
])
```

And, you can search it:

```elixir
# Search with strings:

{:ok, 200, %{hits: %{hits: hits}}} = Repo.search(SomeModel, "meatloaf")

# Search using the elasticsearch DSL:

query = %{
  query: %{bool: %{must: [%{match: %{name: "meatloaf"}}]}}
}

{:ok, 200, %{hits: %{hits: hits}}} = Repo.search(Food, query)

# Or, use the macro provided by Tirexs:

import Tirexs.Search

query = search do
  query do
    bool do
      must do
        match "name", "meatloaf"
      end
    end
  end
end

{:ok, 200, %{hits: %{hits: hits}}} = Repo.search(Food, query)
```

### ElasicSync.SyncRepo

Imagine you're building an app that uses Ecto. You want to synchronize changes that are made in the database with your ElasticSearch index. This is where `ElasticSync.SyncRepo` comes in handy!

```elixir
defmodule MyApp.SyncRepo do
  use ElasticSync.SyncRepo, ecto: MyApp.Repo
end
```

Now, anytime you make a change to one of your models, just use the `SyncRepo` instead of your app's `Repo`.

The `SyncRepo` will only push those changes to ElasticSearch if the save operation is successful. However, you might want to handle the scenario where an HTTP request fails. For example:

```elixir
changeset = Foo.changeset(%Food{id: 1}, %{"name" => "poison"})

case SyncRepo.insert(changeset) do
  {:ok, record} ->
    # everything was successful!
  {:error, changeset} ->
    # ecto had an error
  {:error, status, response} ->
    # something bad happened when communicating with ElasticSearch
end
```

### Mix.Tasks.ElasticSync.Reindex

Now, to reindex your models, you can simply run:

```
$ mix elastic_sync.reindex MyApp.SyncRepo MyApp.SomeModel
```

### Configuring the Elasticsearch endpoint

ElasticSync is build on top of [Tirexs](https://github.com/Zatvobor/tirexs), which offers two ways to customize the Elasticsearch endpoint:

1. By setting the `ES_URI` environment variable.
2. Using `Mix.Config`:

```elixir
config :tirexs, :uri, "http://your-endpoint.com:9200"
```

## Development

The easiest way to run the tests locally is by using docker-compose.

```
$ git clone git@github.com:promptworks/elastic_sync
$ cd elastic_sync
$ docker-compose run app mix test
```

To run the tests against a specific elasticsearch version, you can use the `ES_VERSION` environment variable.

```
$ docker-compose stop
$ export ES_VERSION=1.7.6
$ docker-compose run app mix test
```

## TODO

+ [ ] Create indexes with a default analyzer.
+ [ ] Allow developers to customize mappings (#5).
+ [ ] Better output for the mix task.
