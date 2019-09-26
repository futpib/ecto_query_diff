defmodule EctoQueryDiff do
  use Synex

  @moduledoc """
  Documentation for EctoQueryDiff.
  """

  defmacrop plan(query, operation, adapter, counter) do
    if Kernel.function_exported?(Ecto.Query.Planner, :plan, 4) do
      # ecto 3.1
      quote location: :keep do
        Ecto.Query.Planner.plan(unquote(query), unquote(operation), unquote(adapter), unquote(counter))
      end
    else
      # ecto 3.2
      quote location: :keep do
        Ecto.Query.Planner.plan(unquote(query), unquote(operation), unquote(adapter))
      end
    end
  end

  def diff(a, b, opts \\ []) do
    a = plan_normalize(a, opts)
    b = plan_normalize(b, opts)

    MapDiff.diff(a, b)
  end

  def plan_normalize(query, opts \\ []) do
    operation = Keyword.get(opts, :operation, :all)
    adapter = Keyword.get(opts, :adapter, Ecto.Adapters.Postgres)
    counter = Keyword.get(opts, :counter, 0)

    {query, params, _} = plan(query, operation, adapter, counter)
    {query, _} = Ecto.Query.Planner.normalize(query, operation, adapter, counter)

    query =
      query
      |> walk_map(&strip_debug_info/1)
      |> walk_map(&workaround_nil_params/1)

    keys(%{ query, params })
  end

  defp walk_map(%Ecto.Query{} = query, f) do
    query
    |> f.()
    |> Map.to_list()
    |> Map.new(fn {key, value} -> {key, walk_map(value, f)} end)
  end

  defp walk_map(list, f) when is_list(list) do
    list
    |> Enum.map(fn item -> walk_map(item, f) end)
  end

  defp walk_map(x, f) do
    f.(x)
  end

  defp strip_debug_info(%{ file: _file, line: _line } = x) do
    x
    |> Map.drop([ :file, :line ])
  end

  defp strip_debug_info(x) do
    x
  end

  defp workaround_nil_params(%{ params: nil } = x) do
    x
    |> Map.put(:params, [])
  end

  defp workaround_nil_params(x) do
    x
  end
end
