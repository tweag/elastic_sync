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

### ElasticSync.Schema

Like Ecto, ElasticSync has a concept of a schema and a repo. Here's how you'd configure your schema:

```elixir
defmodule MyApp.SomeModel do
  defstruct [:id, :name]

  use ElasticSync.Schema,
    index: "some_model",
    type: "some_model"

  @doc """
  Convert a struct to a plain ol' map. This will become our document.
  """
  def to_search_document(record) do
    Map.take(record, [:id, :name])
  end
end
```

Great. Now, you communicate with ElasticSearch.

```elixir
alias MyApp.SomeModel
alias ElasticSync.Repo

{:ok, 201, _response} = Repo.insert(%SomeModel{id: 1})
{:ok, 200, _response} = Repo.update(%SomeModel{id: 1, name: "meatloaf"})
{:ok, 200, _response} = Repo.delete(%SomeModel{id: 1})

{:ok, 200, _response} = Repo.insert_all(SomeModel, [
  %SomeModel{id: 1, name: "cheesecake"},
  %SomeModel{id: 2, name: "applesauce"},
  %SomeModel{id: 3, name: "sausage"}
])
```

### ElasicSync.SyncRepo

Imagine you're building an app that uses Ecto. You want to synchronize changes that are made in the database with your ElasticSearch index. This is where `ElasticSync.SyncRepo` comes in handy!

```elixir
defmodule MyApp.SyncRepo do
  use ElasticSync.SyncRepo, ecto: MyApp.Repo
end
```

Now, anytime you make a change to one of your models, just use the `SyncRepo` instead of your app's `Repo`.

The `SyncRepo` will only push those changes to ElasticSearch if the save operation was successful. However, you might want to handle the possibility that HTTP request failed. For example:

```elixir
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

### More Configuration

`ElasticSync` is build on top of [`Tirexs`](https://github.com/Zatvobor/tirexs). So, if you need further configuration, you might want to check there.
