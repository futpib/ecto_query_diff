defmodule EctoQueryDiffTest do
  use Synex
  use ExUnit.Case
  import Ecto.Query
  doctest EctoQueryDiff

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field :email, :string
    end
  end

  defmodule Customer do
    use Ecto.Schema

    schema "customers" do
      field :email, :string
    end
  end

  test "trivially equal queries" do
    a = User |> where(email: "foo@bar")
    b = User |> where(email: "foo@bar")

    assert EctoQueryDiff.diff(a, b) === %{changed: :equal, value: EctoQueryDiff.plan_normalize(a)}
  end

  test "equal queries" do
    a = User |> where(email: "foo@bar")
    b = from(user in User, where: user.email == "foo@bar")

    assert EctoQueryDiff.diff(a, b) === %{changed: :equal, value: EctoQueryDiff.plan_normalize(a)}
  end

  test "equal queries, diff planned & normalized" do
    a = User |> where(email: "foo@bar") |> EctoQueryDiff.plan_normalize()
    b = from(user in User, where: user.email == "foo@bar") |> EctoQueryDiff.plan_normalize()

    assert EctoQueryDiff.diff(a, b) === %{changed: :equal, value: EctoQueryDiff.plan_normalize(a)}
  end

  test "queries with different params" do
    email_a = "a@bar"
    email_b = "b@bar"

    a = User |> where(email: ^email_a)
    b = from(user in User, where: user.email == ^email_b)

    %{ query: a_planned } = EctoQueryDiff.plan_normalize(a)

    assert EctoQueryDiff.diff(a, b) === %{
      changed: :map_change,
      value: %{
        query: %{
          changed: :equal,
          value: a_planned,
        },
        params: %{
          changed: :primitive_change,
          removed: [email_a],
          added: [email_b],
        }
      },
      added: %{
        params: [email_b],
      },
      removed: %{
        params: [email_a],
      },
    }
  end

  test "queries with different schemas" do
    a = User |> where(email: "foo@bar")
    b = from(customer in Customer, where: customer.email == "foo@bar")

    %{ query: a_planned } = EctoQueryDiff.plan_normalize(a)
    %{ query: b_planned } = EctoQueryDiff.plan_normalize(b)

    diff = EctoQueryDiff.diff(a, b)

    assert diff[:changed] === :map_change
    assert diff[:value][:params][:changed] === :equal
    assert diff[:value][:query][:changed] === :map_change

    keys(
      %{
        aliases,
        assocs,
        combinations,
        distinct,
        group_bys,
        havings,
        joins,
        limit,
        lock,
        offset,
        order_bys,
        prefix,
        preloads,
        select,
        updates,
        wheres,
        windows,
        with_ctes,

        from,
        sources,
      }
    ) = diff[:value][:query][:value]

    [
      aliases,
      assocs,
      combinations,
      distinct,
      group_bys,
      havings,
      joins,
      limit,
      lock,
      offset,
      order_bys,
      prefix,
      preloads,
      select,
      updates,
      wheres,
      windows,
      with_ctes,
    ] |> Enum.each(fn change ->
      assert change[:changed] === :equal
    end)

    assert from[:changed] === :map_change
    assert from[:added] === b_planned.from
    assert from[:removed] === a_planned.from

    assert sources[:changed] === :primitive_change
    assert sources[:added] === b_planned.sources
    assert sources[:removed] === a_planned.sources
  end
end
