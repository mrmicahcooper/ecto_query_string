defmodule EctoQueryStringTest do
  use ExUnit.Case, async: true
  use QueryHelpers
  import EctoQueryString
  import Ecto.Query

  test ".fields gets the fields from a query.from" do
    query = from(f in Foo)
    assert schema_fields(query) == ~w[description foo id title]
  end

  test ".queryable returns the field if its in the query's schema" do
    query = from(f in Foo)
    assert queryable(query, "title") == :title
    assert queryable(query, "description") == :description
    assert queryable(query, "bar") == nil
  end

  setup do
    query = from(user in User)
    {:ok, %{query: query}}
  end

  test "all", %{query: query} do
    querystring = ""
    string_query = query(query, querystring)
    expected_query = from(user in User)
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE Key = value", %{query: query} do
    querystring = "foo=bar&username=foo"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: user.username == ^"foo")
    assert_queries_match(string_query, expected_query)
  end

  test("WHERE key IN value", %{query: query}) do
    querystring = "email=user@clank.us,micah@clank.us&username=mrmicahcooper"
    string_query = query(query, querystring)

    expected_query =
      from(
        user in User,
        where: user.email in ^["user@clank.us", "micah@clank.us"],
        where: user.username == ^"mrmicahcooper"
      )

    assert_queries_match(string_query, expected_query)
  end

  test "WHERE Key != value", %{query: query} do
    querystring = "!username=mrmicahcooper"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: user.username != ^"mrmicahcooper")
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key LIKE value%", %{query: query} do
    querystring = "~email=user*"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: like(user.email, ^"user%"))
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key LIKE %value", %{query: query} do
    querystring = "~email=*clank.us"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: like(user.email, ^"%clank.us"))
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key LIKE %value%", %{query: query} do
    querystring = "~email=*clank.us*"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: like(user.email, ^"%clank.us%"))
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key ILIKE value%", %{query: query} do
    querystring = "i~email=*clank.us*"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: ilike(user.email, ^"%clank.us%"))
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key ILIKE %value", %{query: query} do
    querystring = "i~email=*clank.us"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: ilike(user.email, ^"%clank.us"))
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key ILIKE %value%", %{query: query} do
    querystring = "i~email=*@*"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: ilike(user.email, ^"%@%"))
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key > value", %{query: query} do
    querystring = "...age=30:."
    string_query = query(query, querystring)
    expected_query = from(user in User, where: user.age > ^"30")
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key < value", %{query: query} do
    querystring = "...age=.:100"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: user.age < ^"100")
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key < max and key > min ", %{query: query} do
    querystring = "...age=100:200"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: user.age > ^"100" and user.age < ^"200")
    assert_queries_match(string_query, expected_query)
  end

  test "LIMIT max", %{query: query} do
    querystring = "...=.:2"
    string_query = query(query, querystring)
    expected_query = from(user in User, limit: ^"2")
    assert_queries_match(string_query, expected_query)
  end

  test "OFFSET min", %{query: query} do
    querystring = "...=2:."
    string_query = query(query, querystring)
    expected_query = from(user in User, offset: ^"2")
    assert_queries_match(string_query, expected_query)
  end

  test "OFFSET min and LIMIT max", %{query: query} do
    querystring = "...=100:150"
    string_query = query(query, querystring)
    expected_query = from(user in User, limit: ^"150", offset: ^"100")
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE key NOT IN value", %{query: query} do
    querystring = "!email=a@b.co,c@d.co"
    string_query = query(query, querystring)
    expected_query = from(user in User, where: user.email not in ^["a@b.co", "c@d.co"])
    assert_queries_match(string_query, expected_query)
  end

  test "OR WHERE key = value", %{query: query} do
    querystring = "/email=a@b.co"
    string_query = query(query, querystring)
    expected_query = from(user in User, or_where: user.email == ^"a@b.co")
    assert_queries_match(string_query, expected_query)
  end

  test "OR WHERE key != value", %{query: query} do
    querystring = "/!email=a@b.co"
    string_query = query(query, querystring)
    expected_query = from(user in User, or_where: user.email != ^"a@b.co")
    assert_queries_match(string_query, expected_query)
  end

  test "OR WHERE key NOT IN value", %{query: query} do
    querystring = "/!email=a@b.co,c@d.co"
    string_query = query(query, querystring)
    expected_query = from(user in User, or_where: user.email not in ^["a@b.co", "c@d.co"])
    assert_queries_match(string_query, expected_query)
  end

  test "OR WHERE key IN value", %{query: query} do
    querystring = "/email=a@b.co,c@d.co"
    string_query = query(query, querystring)
    expected_query = from(user in User, or_where: user.email in ^["a@b.co", "c@d.co"])
    assert_queries_match(string_query, expected_query)
  end

  test "SELECT values", %{query: query} do
    querystring = "@=username,email"
    string_query = query(query, querystring)
    expected_query = from(user in User, select: ^[:username, :email])
    assert_queries_match(string_query, expected_query)
  end

  test "ORDER_BY values ASC", %{query: query} do
    querystring = "$asc=username,email"
    string_query = query(query, querystring)
    expected_query = from(user in User, order_by: ^[asc: :username, asc: :email])
    assert_queries_match(string_query, expected_query)
  end

  test "ORDER_BY values DESC", %{query: query} do
    querystring = "$desc=username"
    string_query = query(query, querystring)
    expected_query = from(user in User, order_by: ^[desc: :username])
    assert_queries_match(string_query, expected_query)
  end
end
