defmodule EctoQueryString do
  import Ecto.Query
  # /"!@$#*()-_;:',.~[]"

  def query(query, ""), do: query(query, %{})
  def query(query, nil), do: query(query, %{})

  def query(query, %{} = params) do
    Enum.reduce(params, query, &dynamic_segment/2)
  end

  def query(query, querystring) when is_binary(querystring) do
    params = URI.decode_query(querystring)
    query(query, params)
  end

  def queryable(query, field) do
    if field in schema_fields(query), do: String.to_atom(field)
  end

  def selectable(query, fields_string) do
    fields = fields_string |> String.split(",") |> Enum.map(&String.trim/1)
    schema_fields = schema_fields(query)

    for field <- fields, field in schema_fields do
      String.to_atom(field)
    end
  end

  def schema_fields(query) do
    query.from.source
    |> elem(1)
    |> apply(:__schema__, [:fields])
    |> Enum.map(&to_string/1)
  end

  defp dynamic_segment({"select", value}, acc) do
    from(acc, select: ^selectable(acc, value))
  end

  defp dynamic_segment({"limit", value}, acc), do: from(acc, limit: ^value)
  defp dynamic_segment({"offset", value}, acc), do: from(acc, offset: ^value)

  defp dynamic_segment({"greater:" <> key, value}, acc) do
    if new_key = queryable(acc, key) do
      from(acc, where: ^dynamic([q], field(q, ^new_key) > ^value))
    else
      acc
    end
  end

  defp dynamic_segment({"less:" <> key, value}, acc) do
    if new_key = queryable(acc, key) do
      from(acc, where: ^dynamic([q], field(q, ^new_key) < ^value))
    else
      acc
    end
  end

  defp dynamic_segment({"range:" <> key, value}, acc) do
    if new_key = queryable(acc, key) do
      case String.split(value, ":") do
        [".", "."] ->
          acc

        [".", max] ->
          from(acc, where: ^dynamic([q], field(q, ^new_key) < ^max))

        [min, "."] ->
          from(acc, where: ^dynamic([q], field(q, ^new_key) > ^min))

        [min, max] ->
          from(acc, where: ^dynamic([q], field(q, ^new_key) > ^min and field(q, ^new_key) < ^max))

        :else ->
          acc
      end
    else
      acc
    end
  end

  defp dynamic_segment({"ascend", values}, acc) do
    order_values = selectable(acc, values)
    from(acc, order_by: ^order_values)
  end

  defp dynamic_segment({"descend", values}, acc) do
    order_values =
      selectable(acc, values)
      |> Enum.map(fn value -> {:desc, value} end)

    from(acc, order_by: ^order_values)
  end

  defp dynamic_segment({"ilike:" <> key, value}, acc) do
    value = String.replace(value, "*", "%")
    new_key = queryable(acc, key)
    dynamic = dynamic([q], ilike(field(q, ^new_key), ^value))
    from(acc, where: ^dynamic)
  end

  defp dynamic_segment({"like:" <> key, value}, acc) do
    value = String.replace(value, "*", "%")
    new_key = queryable(acc, key)
    dynamic = dynamic([q], like(field(q, ^new_key), ^value))
    from(acc, where: ^dynamic)
  end

  defp dynamic_segment({"!or:" <> key, value}, acc) do
    value = String.split(value, ",")
    new_key = queryable(acc, key)

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) != ^value))

      {key, value} when is_list(value) ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) not in ^value))

      _ ->
        acc
    end
  end

  defp dynamic_segment({"!" <> key, value}, acc) do
    value = String.split(value, ",")
    new_key = queryable(acc, key)

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, where: ^dynamic([query], field(query, ^key) != ^value))

      {key, value} when is_list(value) ->
        from(acc, where: ^dynamic([query], field(query, ^key) not in ^value))

      _ ->
        acc
    end
  end

  defp dynamic_segment({"or:" <> key, value}, acc) do
    value = String.split(value, ",")
    new_key = queryable(acc, key)

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) == ^value))

      {key, value} when is_list(value) ->
        from(acc, or_where: ^dynamic([query], field(query, ^key) in ^value))

      _ ->
        acc
    end
  end

  defp dynamic_segment({key, value}, acc) do
    value = String.split(value, ",")
    new_key = queryable(acc, key)

    case {new_key, value} do
      {nil, _} ->
        acc

      {_, nil} ->
        acc

      {key, [value]} ->
        from(acc, where: ^dynamic([query], field(query, ^key) == ^value))

      {key, value} when is_list(value) ->
        from(acc, where: ^dynamic([query], field(query, ^key) in ^value))

      _ ->
        acc
    end
  end
end
