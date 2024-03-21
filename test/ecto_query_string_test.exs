defmodule EctoQueryStringTest do
  use ExUnit.Case, async: true
  use QueryHelpers
  import EctoQueryString
  import Ecto.Query

  setup do
    query = from(user in User)
    {:ok, %{query: query}}
  end

  test ".queryable returns the field if its in the query's schema" do
    query = from(f in Foo)
    assert queryable(query, "title") == {:field, :title, :string, nil}
    assert queryable(query, "description") == {:field, :description, :string, nil}
    assert queryable(query, "bar") == {:field, nil, :no_field, nil}
    assert queryable(query, "bars.name") == {:assoc, :bars, :name, :string, nil}

    assert queryable(query, "bars.name", "one, two") ==
             {:assoc, :bars, :name, :string, ["one", "two"]}
  end

  test "all", %{query: query} do
    querystring = ""
    string_query = query(query, querystring, [])
    expected_query = from(user in User)
    assert_queries_match(string_query, expected_query)
  end

  test "WHERE Key = value", %{query: query} do
    querystring = "foo=bar&username=foo"
    string_query = query(query, querystring, [:username])
    expected_query = from(user in User, where: user.username == ^"foo")
    assert_queries_match(string_query, expected_query)
  end

  test("WHERE key IN value", %{query: query}) do
    querystring = "email=user@clank.us,micah@clank.us&username=mrmicahcooper"
    string_query = query(query, querystring, [:email, :username])

    expected_query =
      from(
        user in User,
        where: user.email in ^["user@clank.us", "micah@clank.us"],
        where: user.username == ^"mrmicahcooper"
      )

    assert_queries_match(string_query, expected_query)
  end

  test("JOINS t2 ON t1.foreign_key = t1.primary_key WHERE t2.key = value") do
    querystring = "bars.name=coolname"
    query = from(f in Foo)
    string_query = query(query, querystring, ["bars.name"])

    expected_query =
      from(
        foo in Foo,
        join: bars in assoc(foo, :bars),
        where: bars.name == ^"coolname"
      )

    assert_queries_match(string_query, expected_query)
  end

  test("JOINS t2 ON t1.foreign_key = t1.primary_key WHERE t2.key IN value") do
    querystring = "bars.name=cool,name"
    query = from(f in Foo)
    string_query = query(query, querystring, ["bars.name"])

    expected_query =
      from(
        foo in Foo,
        join: bars in assoc(foo, :bars),
        where: bars.name in ^~w[cool name]
      )

    assert_queries_match(string_query, expected_query)
  end

  test "WHERE Key != value", %{query: query} do
    querystring = "!username!=mrmicahcooper"
    string_query = query(query, querystring, [:username])
    expected_query = from(user in User, where: user.username != ^"mrmicahcooper")
    assert_queries_match(string_query, expected_query)
  end

  # test "WHERE key LIKE value%", %{query: query} do
  #   querystring = URI.encode_www_form("like:email=user**")
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: like(user.email, ^"user%"))
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test("JOINS t2 ON t1.foreign_key = t1.primary_key WHERE t2.key LIKE value") do
  #   querystring = "like:bars.name=micah*"
  #   query = from(f in Foo)
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(
  #       foo in Foo,
  #       join: bars in assoc(foo, :bars),
  #       where: like(bars.name, ^"micah%")
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key LIKE %value", %{query: query} do
  #   querystring = "like:email=*clank.us"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: like(user.email, ^"%clank.us"))
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test("JOINS t2 ON t1.foreign_key = t1.primary_key WHERE t2.key ILIKE value") do
  #   querystring = "ilike:bars.name=micah*"
  #   query = from(f in Foo)
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(
  #       foo in Foo,
  #       join: bars in assoc(foo, :bars),
  #       where: ilike(bars.name, ^"micah%")
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key LIKE %value%", %{query: query} do
  #   querystring = "like:email=*clank.us*"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: like(user.email, ^"%clank.us%"))
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key ILIKE value%", %{query: query} do
  #   querystring = "ilike:email=*clank.us*"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: ilike(user.email, ^"%clank.us%"))
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key ILIKE %value", %{query: query} do
  #   querystring = "ilike:email=*clank.us"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: ilike(user.email, ^"%clank.us"))
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key ILIKE %value%", %{query: query} do
  #   querystring = "ilike:email=*@*"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: ilike(user.email, ^"%@%"))
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key > value", %{query: query} do
  #   querystring = "greater:age=30"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age > ^"30")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key > date_value", %{query: query} do
  #   querystring = "greater:inserted_at=2021-01-01"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.inserted_at > ^"2021-01-01 00:00:00")
  #
  #   assert_queries_match(string_query, expected_query)
  #
  #   assert Ecto.Adapters.SQL.to_sql(:all, Repo, string_query) ==
  #            {
  #              ~S|SELECT u0."id", u0."username", u0."email", u0."age", u0."password_digest", u0."inserted_at", u0."updated_at" FROM "users" AS u0 WHERE (u0."inserted_at" > $1)|,
  #              [~N[2021-01-01 00:00:00]]
  #            }
  # end
  #
  # test "WHERE key >= value", %{query: query} do
  #   querystring = "greaterequal:age=30"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age >= ^"30")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key key > value", %{query: query} do
  #   querystring = "greater:bars.age=30"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(
  #       user in User,
  #       join: bars in assoc(user, :bars),
  #       where: bars.age > ^"30"
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key < value", %{query: query} do
  #   querystring = "less:age=100"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age < ^"100")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key <= value", %{query: query} do
  #   querystring = "lessequal:age=100"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age <= ^"100")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key WHERE key < value", %{query: query} do
  #   querystring = "less:bars.age=100"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(
  #       user in User,
  #       join: bars in assoc(user, :bars),
  #       where: bars.age < ^"100"
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key < max and key > min ", %{query: query} do
  #   querystring = "range:age=100:200"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age > ^"100" and user.age < ^"200")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key < max and key > . (anything)", %{query: query} do
  #   querystring = "range:age=.:100"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age < ^"100")
  #   assert_queries_match(string_query, expected_query)
  #
  #   assert Ecto.Adapters.SQL.to_sql(:all, Repo, string_query) ==
  #            {
  #              ~S|SELECT u0."id", u0."username", u0."email", u0."age", u0."password_digest", u0."inserted_at", u0."updated_at" FROM "users" AS u0 WHERE (u0."age" < $1)|,
  #              [100]
  #            }
  # end
  #
  # test "WHERE key < . (anything) and key > min ", %{query: query} do
  #   querystring = "range:age=100:."
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.age > ^"100")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key WHERE key < value AND key > min", %{
  #   query: query
  # } do
  #   querystring = "range:bars.age=100:200"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(
  #       user in User,
  #       join: bars in assoc(user, :bars),
  #       where: bars.age > ^"100" and bars.age < ^"200"
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "LIMIT max", %{query: query} do
  #   querystring = "limit=2"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, limit: ^"2")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "OFFSET min", %{query: query} do
  #   querystring = "offset=2"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, offset: ^"2")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "WHERE key NOT IN value", %{query: query} do
  #   querystring = "!email=a@b.co,c@d.co"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, where: user.email not in ^["a@b.co", "c@d.co"])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key key != value", %{query: query} do
  #   querystring = "!bars.name=foo"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       where: bars.name != ^"foo"
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key WHERE key NOT IN value", %{query: query} do
  #   querystring = "!bars.name=foo,bar"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       where: bars.name not in ^["foo", "bar"]
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "OR WHERE key = value", %{query: query} do
  #   querystring = "or:email=a@b.co"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, or_where: user.email == ^"a@b.co")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "OR WHERE key != value", %{query: query} do
  #   querystring = "!or:email=a@b.co"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, or_where: user.email != ^"a@b.co")
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key OR WHERE key != value", %{query: query} do
  #   querystring = "!or:bars.name=foo"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       or_where: bars.name != ^"foo"
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key OR WHERE key == value", %{query: query} do
  #   querystring = "or:bars.name=foo"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       or_where: bars.name == ^"foo"
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key OR WHERE key in value", %{query: query} do
  #   querystring = "or:bars.name=foo,bar"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       or_where: bars.name in ^["foo", "bar"]
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "OR WHERE key NOT IN value", %{query: query} do
  #   querystring = "!or:email=a@b.co,c@d.co"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, or_where: user.email not in ^["a@b.co", "c@d.co"])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key OR WHERE t2.key NOT IN t2.value", %{
  #   query: query
  # } do
  #   querystring = "!or:bars.name=foo,bar"
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       or_where: bars.name not in ^["foo", "bar"]
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "OR WHERE key IN value", %{query: query} do
  #   querystring = "or:email=a@b.co,c@d.co"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, or_where: user.email in ^["a@b.co", "c@d.co"])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "JOINS t2 ON t1.foreign_key = t1.primary_key SELECT t2.value", %{query: query} do
  #   querystring = "select=username,email,bars.name,bars.content,foos.title,foobars.name"
  #
  #   string_query = query(query, querystring)
  #
  #   expected_query =
  #     from(user in User,
  #       join: bars in assoc(user, :bars),
  #       join: foos in assoc(user, :foos),
  #       join: foobars in assoc(user, :foobars),
  #       select: [
  #         {:bars, [:id, :user_id, :content, :name]},
  #         {:foos, [:id, :user_id, :title]},
  #         {:foobars, [:id, :foo_id, :name]},
  #         :email,
  #         :username,
  #         :id
  #       ],
  #       preload: [foos: foos, bars: bars, foobars: foobars]
  #     )
  #
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "SELECT values", %{query: query} do
  #   querystring = "select=username,email"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, select: ^[:email, :username])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "SELECT values with 'fields'", %{query: query} do
  #   querystring = "fields=username,email"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, select: ^[:email, :username])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "ORDER_BY values with order", %{query: query} do
  #   querystring = "order=username,-email"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, order_by: ^[asc: :username, desc: :email])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # test "ORDER_BY values DESC with sort", %{query: query} do
  #   querystring = "order=-username"
  #   string_query = query(query, querystring)
  #   expected_query = from(user in User, order_by: ^[desc: :username])
  #   assert_queries_match(string_query, expected_query)
  # end
  #
  # describe "date_format/2" do
  #   test "date string for naive_datetime" do
  #     assert date_time_format("2023-01-01", :naive_datetime) == "2023-01-01 00:00:00"
  #     assert date_time_format("2023-01-01 12:12", :naive_datetime) == "2023-01-01 12:12:00"
  #   end
  #
  #   test "date string for naive_datetime_usec" do
  #     assert date_time_format("2023-01-01", :naive_datetime_usec) == "2023-01-01 00:00:00.000000"
  #   end
  #
  #   test "date string for utc_datetime_usec" do
  #     assert date_time_format("2023-01-01", :utc_datetime_usec) == "2023-01-01 00:00:00.000000Z"
  #
  #     assert date_time_format("2023-01-01T00:00:00.000000Z", :utc_datetime_usec) ==
  #              "2023-01-01 00:00:00.000000Z"
  #   end
  #
  #   test "time string for time" do
  #     assert date_time_format("11:01:31", :time) == "11:01:31"
  #     assert date_time_format("11:01:31.123436", :time) == "11:01:31"
  #   end
  #
  #   test "time string for time_usec" do
  #     assert date_time_format("11:01:31.123436", :time_usec) == "11:01:31.123436"
  #   end
  #
  #   test "non date or time" do
  #     assert date_time_format("mrmicahcooper", :string) == "mrmicahcooper"
  #   end
  #
  #   test "actual date passed in" do
  #     assert date_time_format(~T[00:00:00], :time) == ~T[00:00:00]
  #   end
  # end
end
