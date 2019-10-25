defmodule EctoQueryString do
  import Ecto.Query

  alias EctoQueryString.Reflection
  import Logger, only: [debug: 1]

  @moduledoc """

  Compose an `Ecto.Query` with a querystring

  ## Usage

  Say you have the following schemas:

  ```
  defmodule Foo do
    use Ecto.Schema

    schema "foos" do
      field(:name, :string)
      field(:age, :integer)
      has_many(:bars, Bar)
    end
  end

  defmodule Bar do
    use Ecto.Schema

    schema "bars" do
      field(:title, :string)
      field(:likes, :integer)
      belongs_to(:foo, Foo)
    end
  end

  ```

  You can do things like this:
  ```
  query = Ecto.Query.from(user in User)
  query_string =  "username=mrmicahcooper&greater:age=18&limit=10"
  EctoQueryString.query(query, query_string)
  ```
  And get:
  ```
  Ecto.Query.from(u0 in User,
    where: u0.age > ^"18",
    where: u0.username == ^"mrmicahcooper",
    limit: ^"10"
  )
  ```

  Here is the full DSL

  ```
  # Basic Queries
  "name=micah"                => where: foo.name = ^"micah"
  "name=micah,bob"            => where: foo.name in ^["micah", "bob"]
  "!name=micah"               => where: foo.name != ^"micah"
  "!name=micah,bob"           => where: foo.name not in ^["micah", "bob"]
  "like:foo=bar*"             => where: like(x.foo, ^"bar%")
  "like:foo=*bar"             => where: like(x.foo, ^"%bar")
  "like:name=*micah*"         => where: like(foo.name, ^"%micah%")
  "ilike:name=micah*"         => where: ilike(foo.name, ^"micah%")
  "ilike:name=*micah"         => where: ilike(foo.name, ^"%micah")
  "ilike:foo=*bar*"           => where: ilike(x.foo, ^"%bar%")
  "less:age=99"               => where: foo.age < 99
  "greater:age=40"            => where: foo.age > 40
  "range:age=40:99"           => where: foo.age < 99 and foo.age > 40
  "or:name=micah"             => or_where: foo.name = ^"micah"
  "or:name=micah,bob"         => or_where: foo.name in ^["micah", "bob"]
  "!or:name=bar"              => or_where: foo.name != ^"bar"
  "!or:name=micah,bob"        => or_where: foo.name not in ^["bar", "baz"]
  "select=foo,bar"            => select: [:foo, :bar]
  "fields=foo,bar"            => select: [:foo, :bar]
  "limit=.:99"                => limit: 99
  "offset=40:."               => offset: 40
  "between=40:99"             => offset: 40, limit: 99
  "order=foo,-bar,baz"        => order_by: [asc: :foo, desc: :bar, asc: :baz]
  #Incorporating Associated Tables
  "bars.title=micah"          => join: bars in assoc(foo, :bars), where: bars.title = ^"micah"
  "bars.title=micah,bob"      => join: bars in assoc(foo, :bars), where: bars.title in ^["micah", "bob"]
  "!bars.title=micah"         => join: bars in assoc(foo, :bars), where: bars.title != ^"micah")
  "!bars.title=micah,bob"     => join: bars in assoc(foo, :bars), where: bars.title not in ^["micah", "bob"])
  "like:bars.title=micah*"    => join: bars in assoc(foo, :bars), where: like(bars.title, ^"bar%")
  "like:bars.title=*micah"    => join: bars in assoc(foo, :bars), where: like(bars.title, ^"%bar")
  "like:bars.title=*micah*"   => join: bars in assoc(foo, :bars), where: like(bars.title, ^"%bar%")
  "ilike:bars.title=micah*"   => join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"micah%")
  "ilike:bars.title=*micah"   => join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"%micah")
  "ilike:bars.title=*micah* " => join: bars in assoc(foo, :bars), where: ilike(bars.title, ^"%micah%")
  "less:bars.likes=99"        => join: bars in assoc(foo, :bars), where: bars.likes < 99
  "greater:bars.likes=99"     => join: bars in assoc(foo, :bars), where: bars.likes > 99
  "range:bars.likes=40:99"    => join: bars in assoc(foo, :bars), where: bars.likes< 99 and bars.likes > 40
  "or:bars.title=micah"       => join: bars in assoc(foo, :bars), or_where: bars.title == ^"micah"
  "or:bars.title=micah,bob"   => join: bars in assoc(foo, :bars), or_where: bars.title in ^["micah", "bob"
  "!or:bars.title=micah"      => join: bars in assoc(foo, :bars), or_where: bars.title != ^"micah"
  "!or:bars.title=micah,bob"  => join: bars in assoc(foo, :bars), or_where: bars.title not in ^["micah", "bob"
  ```
  """

  @spec query(Ecto.Query, binary() | map() | keyword() | nil) :: Ecto.Query
  @doc """
  Uses a querystring or a map of params to extend an `Ecto.Query`

  This DSL provides basic query functions with the goal of handling the
  majority of your filtering, ordering, and basic selects.

  """
  def query(query, ""), do: query(query, [])
  def query(query, nil), do: query(query, [])

  def query(query, params) when is_map(params) do
    params = params |> Enum.into([])
    query(query, params)
  end

  def query(query, params) when is_list(params) do
    Enum.reduce(params, query, &dynamic_segment/2)
  end

  def query(query, querystring) when is_binary(querystring) do
    params = URI.query_decoder(querystring) |> Enum.to_list()
    query = query(query, params)
    unless Mix.env() == :test, do: debug(inspect(query))
    query
  end

  @doc false
  def queryable(query, field, value \\ nil) do
    value =
      if value do
        String.split(value, ",") |> Enum.map(&String.trim/1)
      end

    schema = Reflection.source_schema(query)

    case String.split(field, ".", trim: true) do
      [field] ->
        {:field, Reflection.field(schema, field), value}

      [assoc, field] ->
        if assoc_schema = Reflection.assoc_schema(schema, assoc) do
          assoc = String.to_atom(assoc)
          field = Reflection.field(assoc_schema, field)
          {:assoc, assoc, field, value}
        end

      _ ->
        nil
    end
  end

  @doc false
  def orderable(query, fields_string) do
    fields =
      fields_string
      |> String.split(",", trim: true)
      |> Enum.map(&order_field/1)

    schema_fields =
      query
      |> Reflection.source_schema()
      |> Reflection.schema_fields()

    for {order, field} <- fields, field in schema_fields do
      {order, String.to_atom(field)}
    end
  end

  defp order_field("-" <> field), do: {:desc, field}
  defp order_field(field), do: {:asc, field}

  def selectable([field], {query, acc}) do
    case Reflection.source_schema(query) |> Reflection.field(field) do
      nil ->
        {query, acc}

      selection_field ->
        {query, acc ++ [nil: selection_field]}
    end
  end

  def selectable([assoc, field], {query, acc}) do
    schema = Reflection.source_schema(query)

    case Reflection.assoc_schema(schema, assoc) |> Reflection.field(field) do
      nil ->
        {query, acc}

      assoc_selection_field ->
        assoc_field = String.to_atom(assoc)
        {query, acc ++ [{assoc_field, assoc_selection_field}]}
    end
  end

  defp select_into({nil, value}, acc), do: acc ++ value
  defp select_into({key, value}, acc), do: acc ++ [{key, value}]

  defp dynamic_segment({"select", value}, acc) do
    select_segment =
      value
      |> String.split(",", trim: true)
      |> Enum.map(&String.split(&1, ".", trim: true))
      |> Enum.reduce({acc, []}, &selectable/2)
      |> elem(1)
      |> Enum.group_by(fn {k, _} -> k end, fn {_, v} -> v end)
      |> Enum.reduce([], &select_into/2)

    join_fields = for {key, _} <- select_segment, uniq: true, do: key

    acc =
      Enum.reduce(join_fields, acc, fn assoc_field, query ->
        from(parent in query,
          join: child in assoc(parent, ^assoc_field),
          preload: [{^assoc_field, child}]
        )
      end)

    from(acc, select: ^select_segment)
  end

  defp dynamic_segment({"fields", value}, acc) do
    dynamic_segment({"select", value}, acc)
  end

  defp dynamic_segment({"limit", value}, acc), do: from(acc, limit: ^value)
  defp dynamic_segment({"offset", value}, acc), do: from(acc, offset: ^value)

  defp dynamic_segment({"greater:" <> key, value}, acc) do
    case queryable(acc, key) do
      {:field, nil, _} ->
        acc

      {:field, key, _} ->
        from(query in acc, where: field(query, ^key) > ^value)

      {:assoc, assoc_field, key, _} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: field(child, ^key) > ^value
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({"less:" <> key, value}, acc) do
    case queryable(acc, key) do
      {:field, nil, _} ->
        acc

      {:field, key, _} ->
        from(query in acc, where: field(query, ^key) < ^value)

      {:assoc, assoc_field, key, _} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: field(child, ^key) < ^value
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({"range:" <> key, value}, acc) do
    case queryable(acc, key) do
      {:field, nil, _} ->
        acc

      {:field, key, _} ->
        case String.split(value, ":", trim: true) do
          [".", "."] ->
            acc

          [".", max] ->
            from(query in acc, where: field(query, ^key) < ^max)

          [min, "."] ->
            from(query in acc, where: field(query, ^key) > ^min)

          [min, max] ->
            from(query in acc,
              where: field(query, ^key) > ^min and field(query, ^key) < ^max
            )

          :else ->
            acc
        end

      {:assoc, assoc_field, key, _} ->
        case String.split(value, ":", trim: true) do
          [".", "."] ->
            acc

          [".", max] ->
            from(parent in acc,
              join: child in assoc(parent, ^assoc_field),
              where: field(child, ^key) < ^max
            )

          [min, "."] ->
            from(parent in acc,
              join: child in assoc(parent, ^assoc_field),
              where: field(child, ^key) > ^min
            )

          [min, max] ->
            from(parent in acc,
              join: child in assoc(parent, ^assoc_field),
              where: field(child, ^key) > ^min and field(child, ^key) < ^max
            )

          :else ->
            acc
        end

      _ ->
        acc
    end
  end

  defp dynamic_segment({"order", values}, acc) do
    order_values = orderable(acc, values)
    from(acc, order_by: ^order_values)
  end

  defp dynamic_segment({"ilike:" <> key, value}, acc) do
    value = String.replace(value, ~r/\*+/, "%")

    case queryable(acc, key) do
      {:field, nil, _} ->
        acc

      {:field, key, _} ->
        from(query in acc, where: ilike(field(query, ^key), ^value))

      {:assoc, assoc_field, key, _} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: ilike(field(child, ^key), ^value)
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({"like:" <> key, value}, acc) do
    value = String.replace(value, ~r/\*+/, "%")

    case queryable(acc, key) do
      {:field, nil, _} ->
        acc

      {:field, key, _} ->
        from(query in acc, where: like(field(query, ^key), ^value))

      {:assoc, assoc_field, key, _} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: like(field(child, ^key), ^value)
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({"!or:" <> key, value}, acc) do
    case queryable(acc, key, value) do
      {:field, nil, _} ->
        acc

      {_, _, nil} ->
        acc

      {:field, key, [value]} ->
        from(query in acc, or_where: field(query, ^key) != ^value)

      {:field, key, value} when is_list(value) ->
        from(query in acc, or_where: field(query, ^key) not in ^value)

      {:assoc, assoc_field, key, [value]} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          or_where: field(child, ^key) != ^value
        )

      {:assoc, assoc_field, key, value} when is_list(value) ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          or_where: field(child, ^key) not in ^value
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({"!" <> key, value}, acc) do
    case queryable(acc, key, value) do
      {:field, nil, _} ->
        acc

      {_, _, nil} ->
        acc

      {:field, key, [value]} ->
        from(query in acc, where: field(query, ^key) != ^value)

      {:field, key, value} when is_list(value) ->
        from(query in acc, where: field(query, ^key) not in ^value)

      {:assoc, assoc_field, key, [value]} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: field(child, ^key) != ^value
        )

      {:assoc, assoc_field, key, value} when is_list(value) ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: field(child, ^key) not in ^value
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({"or:" <> key, value}, acc) do
    case queryable(acc, key, value) do
      {:field, nil, _} ->
        acc

      {_, _, nil} ->
        acc

      {:field, key, [value]} ->
        from(query in acc, or_where: field(query, ^key) == ^value)

      {:field, key, value} when is_list(value) ->
        from(query in acc, or_where: field(query, ^key) in ^value)

      {:assoc, assoc_field, key, [value]} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          or_where: field(child, ^key) == ^value
        )

      {:assoc, assoc_field, key, value} when is_list(value) ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          or_where: field(child, ^key) in ^value
        )

      _ ->
        acc
    end
  end

  defp dynamic_segment({key, value}, acc) do
    case queryable(acc, key, value) do
      {:field, nil, _} ->
        acc

      {_, _, nil} ->
        acc

      {:field, key, [value]} ->
        from(query in acc, where: field(query, ^key) == ^value)

      {:field, key, value} when is_list(value) ->
        from(query in acc, where: field(query, ^key) in ^value)

      {:assoc, assoc_field, key, [value]} ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: field(child, ^key) == ^value
        )

      {:assoc, assoc_field, key, value} when is_list(value) ->
        from(parent in acc,
          join: child in assoc(parent, ^assoc_field),
          where: field(child, ^key) in ^value
        )

      _ ->
        acc
    end
  end
end
