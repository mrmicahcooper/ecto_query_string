defmodule EctoQueryString do
  import Ecto.Query
  #/"!@$#*()-_;:',.~[]"

  def string_query(query, ""), do: string_query(query, %{})

  def string_query(query, nil), do: string_query(query, %{})

  def string_query(query, %{} = params) do
    Enum.reduce(params, query, &dynamic_segment/2)
  end

  def string_query(query, querystring) when is_binary(querystring) do
    params = URI.decode_query(querystring)
    string_query(query, params)
  end

  defp schema_fields(fields_string, query) when is_binary(fields_string) do
    fields_string
    |> String.split(",")
    |> schema_fields(query)
  end

  defp schema_fields(fields, query) when is_list(fields) do
    schema_fields =
      query.from
      |> elem(1)
      |> struct()
      |> Map.from_struct()
      |> Map.keys()
      |> Enum.map(&to_string/1)

    for field <- fields, field in schema_fields, do: String.to_atom(field)
  end

  defp dynamic_segment({"@", value}, acc) do
    attrs = schema_fields(value, acc)
    from(acc, select: ^attrs)
  end

  defp dynamic_segment({"...", value}, acc) do
    case String.split(value, ":") do
      [".", "."] -> acc
      [".", max] -> from(acc, limit: ^max)
      [min, "."] -> from(acc, offset: ^min)
      [min, max] -> from(acc, offset: ^min, limit: ^max)
      :else -> acc
    end
  end

  defp dynamic_segment({"..." <> key, value}, acc) do
    if new_key = schema_fields(key, acc) |> List.first() do
      dynamic =
        case String.split(value, ":") do
          [".", "."] -> acc
          [".", max] -> dynamic([q], field(q, ^new_key) < ^max)
          [min, "."] -> dynamic([q], field(q, ^new_key) > ^min)
          [min, max] -> dynamic([q], field(q, ^new_key) > ^min and field(q, ^new_key) < ^max)
          :else -> acc
        end

      from(acc, where: ^dynamic)
    else
      acc
    end
  end

  defp dynamic_segment({"$asc", values}, acc) do
    order_values = schema_fields(values, acc)
    from(acc, order_by: ^order_values)
  end

  defp dynamic_segment({"$desc", values}, acc) do
    order_values =
      values
      |> schema_fields(acc)
      |> Enum.map(fn value -> {:desc, value} end)

    from(acc, order_by: ^order_values)
  end

  defp dynamic_segment({"i~" <> key, value}, acc) do
    value = String.replace(value, "*", "%")
    [new_key] = schema_fields(key, acc)
    dynamic = dynamic([q], ilike(field(q, ^new_key), ^value))
    from(acc, where: ^dynamic)
  end

  defp dynamic_segment({"~" <> key, value}, acc) do
    value = String.replace(value, "*", "%")
    [new_key] = schema_fields(key, acc)
    dynamic = dynamic([q], like(field(q, ^new_key), ^value))
    from(acc, where: ^dynamic)
  end

  defp dynamic_segment({"!" <> key, value}, acc) do
    value = String.split(value, ",")
    new_key = schema_fields(key, acc) |> List.first()

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, where: ^dynamic([query], field(query, ^key) != ^value))

      {key, value} when is_list(value) ->
        from(acc, where: ^dynamic([query], field(query, ^key) not in ^value))
    end
  end

  defp dynamic_segment({"/!" <> key, value}, acc) do
    value = String.split(value, ",")
    new_key = schema_fields(key, acc) |> List.first()

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) != ^value))

      {key, value} when is_list(value) ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) not in ^value))
    end
  end

  defp dynamic_segment({"/" <> key, value}, acc) do
    value = String.split(value, ",")
    new_key = schema_fields(key, acc) |> List.first()

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) == ^value))

      {key, value} when is_list(value) ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) in ^value))
    end
  end

  defp dynamic_segment({key, value}, acc) do
    value = String.split(value, ",")
    new_key = schema_fields(key, acc) |> List.first()

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, where: ^dynamic([query], field(query, ^key) == ^value))

      {key, value} when is_list(value) ->
        from(acc, where: ^dynamic([query], field(query, ^key) in ^value))
    end
  end
end
