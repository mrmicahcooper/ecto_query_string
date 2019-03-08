defmodule EctoQueryString do
  import Ecto.Query

  alias EctoQueryString.Reflection
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

  def selectable(query, fields_string) do
    fields = fields_string |> String.split(",", trim: true)

    schema_fields =
      query
      |> Reflection.source_schema()
      |> Reflection.schema_fields()

    for field <- fields, field in schema_fields do
      String.to_atom(field)
    end
  end

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

  defp dynamic_segment({"select", value}, acc) do
    from(acc, select: ^selectable(acc, value))
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
