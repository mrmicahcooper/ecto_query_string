defmodule EctoQueryString.ReflectionTest do
  use ExUnit.Case, async: true

  alias EctoQueryString.Reflection
  import Ecto.Query

  describe "schema_fields/1" do
    test "return string representations of a schema's fields" do
      assert Reflection.schema_fields(Foo) == ~w[id foo title description]
    end
  end

  describe "has_field?/2" do
    test "existing field returns true" do
      assert Reflection.has_field?(Foo, "title") == true
    end

    test "non existing field returns true" do
      assert Reflection.has_field?(Foo, "x") == false
    end
  end

  describe "field/2" do
    test "returns field if it exists in the schema" do
      assert Reflection.field(Foo, "title") == :title
    end

    test "returns nil if the field doesn't exist" do
      assert Reflection.field(Foo, "noop") == nil
    end
  end

  describe "has_assoc?/2" do
    test "existing assoc returns true", _ do
      assert Reflection.has_assoc?(Foo, "bars") == true
    end

    test "non existing assoc returns false", _ do
      assert Reflection.has_assoc?(Foo, "bazes") == false
    end
  end

  describe "assoc_schema/2" do
    test "returns the associated schema if present" do
      assert Reflection.assoc_schema(Foo, "bars") == Bar
    end

    test "returns nil associated schema if absent" do
      assert Reflection.assoc_schema(Foo, "bazes") == nil
    end
  end

  describe "source_schema/1" do
    test "returns the source schema from a query" do
      query = from(f in Foo)

      assert Reflection.source_schema(query) == Foo
    end
  end
end
