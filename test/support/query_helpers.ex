defmodule QueryHelpers do
  defmacro __using__(_) do
    quote do
      def assert_queries_match(query1, query2) do
        assert cleaned(query1.wheres) == cleaned(query2.wheres)
        assert cleaned(query1.limit) == cleaned(query2.limit)
        assert cleaned(query1.offset) == cleaned(query2.offset)
        assert cleaned(query1.order_bys) == cleaned(query2.order_bys)
        assert cleaned(query1.joins) == cleaned(query2.joins)
        assert cleaned(query1.select) == cleaned(query2.select)
      end

      def cleaned(%{} = map), do: Map.drop(map, [:file, :line, :on])
      def cleaned(nil), do: nil
      def cleaned(maps), do: Enum.map(maps, &cleaned/1)
    end
  end
end
