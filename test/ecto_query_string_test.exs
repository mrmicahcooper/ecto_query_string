defmodule EctoQueryStringTest do
  use ExUnit.Case, async: true
  import EctoQueryString, only: [string_query: 2]
  import Ecto.Query

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:username, :string)
      field(:email, :string)
      field(:age, :integer)
      field(:password, :string, virtual: true)
      field(:password_digest, :string)
      timestamps()
    end
  end

  defp assert_wheres_match(query1, query2) do
    assert sans_location_data(query1.wheres) == sans_location_data(query2.wheres)
  end

  defp assert_match(attr1, attr2) do
    assert sans_location_data(attr1) == sans_location_data(attr2)
  end

  defp sans_location_data(%{} = map), do: Map.drop(map, [:file, :line])
  defp sans_location_data(maps), do: Enum.map(maps, &sans_location_data/1)

  setup do
    query = from(user in User)
    {:ok, %{query: query}}
  end

  test "all", %{query: query} do
    querystring = ""
    string_query = string_query(query, querystring)
    expected_query = from(user in User)
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE Key = value", %{query: query} do
    querystring = "foo=bar&username=foo"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: user.username == ^"foo")
    assert_wheres_match(string_query, expected_query)
  end

  test("WHERE key IN value", %{query: query}) do
    querystring = "email=user@clank.us,micah@clank.us&username=mrmicahcooper"
    string_query = string_query(query, querystring)

    expected_query =
      from(
        user in User,
        where: user.email in ^["user@clank.us", "micah@clank.us"],
        where: user.username == ^"mrmicahcooper"
      )

    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE Key != value", %{query: query} do
    querystring = "!username=mrmicahcooper"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: user.username != ^"mrmicahcooper")
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key LIKE value%", %{query: query} do
    querystring = "~email=user*"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: like(user.email, ^"user%"))
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key LIKE %value", %{query: query} do
    querystring = "~email=*clank.us"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: like(user.email, ^"%clank.us"))
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key LIKE %value%", %{query: query} do
    querystring = "~email=*clank.us*"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: like(user.email, ^"%clank.us%"))
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key ILIKE value%", %{query: query} do
    querystring = "i~email=*clank.us*"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: ilike(user.email, ^"%clank.us%"))
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key ILIKE %value", %{query: query} do
    querystring = "i~email=*clank.us"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: ilike(user.email, ^"%clank.us"))
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key ILIKE %value%", %{query: query} do
    querystring = "i~email=*@*"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: ilike(user.email, ^"%@%"))
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key > value", %{query: query} do
    querystring = "...age=30:."
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: user.age > ^"30")
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key < value", %{query: query} do
    querystring = "...age=.:100"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: user.age < ^"100")
    assert_wheres_match(string_query, expected_query)
  end

  test "WHERE key < max and key > min ", %{query: query} do
    querystring = "...age=100:200"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: user.age > ^"100" and user.age < ^"200")
    assert_wheres_match(string_query, expected_query)
  end

  test "LIMIT max", %{query: query} do
    querystring = "...=.:2"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, limit: ^"2")
    assert_match(string_query.limit, expected_query.limit)
  end

  test "OFFSET min", %{query: query} do
    querystring = "...=2:."
    string_query = string_query(query, querystring)
    expected_query = from(user in User, offset: ^"2")
    assert_match(string_query.offset, expected_query.offset)
  end

  test "OFFSET min and LIMIT max", %{query: query} do
    querystring = "...=100:150"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, limit: ^"150", offset: ^"100")
    assert_match(string_query.offset, expected_query.offset)
    assert_match(string_query.limit, expected_query.limit)
  end

  test "WHERE key NOT IN value", %{query: query} do
    querystring = "!email=a@b.co,c@d.co"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, where: user.email not in ^["a@b.co", "c@d.co"])
    assert_wheres_match(string_query, expected_query)
  end

  test "OR WHERE key = value", %{query: query} do
    querystring = "/email=a@b.co"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, or_where: user.email == ^"a@b.co")
    assert_wheres_match(string_query, expected_query)
  end

  test "OR WHERE key != value", %{query: query} do
    querystring = "/!email=a@b.co"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, or_where: user.email != ^"a@b.co")
    assert_wheres_match(string_query, expected_query)
  end

  test "OR WHERE key NOT IN value", %{query: query} do
    querystring = "/!email=a@b.co,c@d.co"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, or_where: user.email not in ^["a@b.co", "c@d.co"])
    assert_wheres_match(string_query, expected_query)
  end

  test "OR WHERE key IN value", %{query: query} do
    querystring = "/email=a@b.co,c@d.co"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, or_where: user.email in ^["a@b.co", "c@d.co"])
    assert_wheres_match(string_query, expected_query)
  end

  test "SELECT values", %{query: query} do
    querystring = "@=username,email"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, select: ^[:username, :email])
    assert_match(string_query.select, expected_query.select)
  end

  test "ORDER_BY values ASC", %{query: query} do
    querystring = "$asc=username,email"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, order_by: ^[asc: :username, asc: :email])
    assert_match(string_query.order_bys, expected_query.order_bys)
  end

  test "ORDER_BY values DESC", %{query: query} do
    querystring = "$desc=username"
    string_query = string_query(query, querystring)
    expected_query = from(user in User, order_by: ^[desc: :username])
    assert_match(string_query.order_bys, expected_query.order_bys)
  end
end
