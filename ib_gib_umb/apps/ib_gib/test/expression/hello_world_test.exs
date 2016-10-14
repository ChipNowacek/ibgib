defmodule IbGib.Expression.HelloWorldTest do
  @moduledoc """
  Ah, the dream of ibGib. To be able to do Hello World but with ibGib
  transforms!
  """


  use ExUnit.Case
  require Logger

  alias IbGib.{Expression, Helper}
  import IbGib.Expression
  use IbGib.Constants, :ib_gib
  use IbGib.Constants, :test


  setup context do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(IbGib.Data.Repo)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(IbGib.Data.Repo, {:shared, self()})
    end

    test_name = "#{context.test}" |> String.replace(" ", "_") |> String.replace(",", "_")
    {:ok, test_name: String.to_atom(test_name)}
  end

  @tag :capture_log
  test "hello world then fork instance, text then fork instance, relate" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    _ = Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(@test_identities_1, hw_ib)
    # hw_info = hw_thing |> Expression.get_info!
    # hw_ib_gib = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])

    _ = Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw_instance} =
      hw |> Expression.fork(@test_identities_1, hw_instance_ib)
    # hw_instance_info = hw_instance |> Expression.get_info!
    # hw_instance_ib_gib = Helper.get_ib_gib!(hw_instance_info[:ib], hw_instance_info[:gib])

    _ = Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(@test_identities_1, text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    _ = Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, text_instance} =
      text |> Expression.fork(@test_identities_1, text_instance_ib)
    text_instance_info = text_instance |> Expression.get_info!
    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])

    _ = Logger.debug "gonna rel8"
    # {:ok, {hw_instance_rel8d, text_instance_rel8d}} =
    #   hw_instance |> Expression.rel8(text_instance)
    {:ok, hw_instance_rel8d} =
      hw_instance |> Expression.rel8(text_instance, @test_identities_1, @default_rel8ns, @default_transform_options)
    {:ok, text_instance_rel8d} =
      text_instance |> Expression.rel8(hw_instance_rel8d, @test_identities_1, @default_rel8ns, @default_transform_options)


    assert is_pid(hw_instance_rel8d)
    assert is_pid(text_instance_rel8d)

    assert hw_instance !== hw_instance_rel8d
    assert text_instance !== text_instance_rel8d

    hw_instance_rel8d_info = hw_instance_rel8d |> Expression.get_info!
    hw_instance_rel8d_ib_gib = Helper.get_ib_gib!(hw_instance_rel8d_info[:ib], hw_instance_rel8d_info[:gib])
    _ = Logger.debug "hw_instance_rel8d_info: #{inspect hw_instance_rel8d_info}"
    text_instance_rel8d_info = text_instance_rel8d |> Expression.get_info!
    _text_instance_rel8d_ib_gib = Helper.get_ib_gib!(text_instance_rel8d_info[:ib], text_instance_rel8d_info[:gib])
    _ = Logger.debug "text_instance_rel8d_info: #{inspect text_instance_rel8d_info}"

    assert hw_instance_rel8d_info[:rel8ns][@root_ib_gib] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:rel8ns][@root_ib_gib] === [hw_instance_rel8d_ib_gib]
  end

  @tag :capture_log
  test "hello world then fork instance, text then fork instance, relate property" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    _ = Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(@test_identities_1, hw_ib)
    # hw_info = hw_thing |> Expression.get_info!
    # hw_ib_gib = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])

    _ = Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw_instance} =
      hw |> Expression.fork(@test_identities_1, hw_instance_ib)
    # hw_instance_info = hw_instance |> Expression.get_info!
    # hw_instance_ib_gib = Helper.get_ib_gib!(hw_instance_info[:ib], hw_instance_info[:gib])

    _ = Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(@test_identities_1, text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    _ = Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, text_instance} =
      text |> Expression.fork(@test_identities_1, text_instance_ib)
    text_instance_info = text_instance |> Expression.get_info!
    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])

    _ = Logger.debug "gonna rel8 'text property'"
    # {:ok, {hw_instance_rel8d, text_instance_rel8d}} =
    #   hw_instance |> Expression.rel8(text_instance, ["prop", "text"], ["prop_of"])
    {:ok, hw_instance_rel8d} = hw_instance |> Expression.rel8(text_instance, @test_identities_1, ["prop", "text"], @default_transform_options)
    {:ok, text_instance_rel8d} = text_instance |> Expression.rel8(hw_instance_rel8d, @test_identities_1, ["prop_of", "text_of"], @default_transform_options)

    assert is_pid(hw_instance_rel8d)
    assert is_pid(text_instance_rel8d)

    assert hw_instance !== hw_instance_rel8d
    assert text_instance !== text_instance_rel8d

    hw_instance_rel8d_info = hw_instance_rel8d |> Expression.get_info!
    hw_instance_rel8d_ib_gib = Helper.get_ib_gib!(hw_instance_rel8d_info[:ib], hw_instance_rel8d_info[:gib])
    _ = Logger.debug "hw_instance_rel8d_info: #{inspect hw_instance_rel8d_info}"
    text_instance_rel8d_info = text_instance_rel8d |> Expression.get_info!
    # text_instance_rel8d_ib_gib = Helper.get_ib_gib!(text_instance_rel8d_info[:ib], text_instance_rel8d_info[:gib])
    _ = Logger.debug "text_instance_rel8d_info: #{inspect text_instance_rel8d_info}"

    assert hw_instance_rel8d_info[:rel8ns][@root_ib_gib] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:rel8ns][@root_ib_gib] === [hw_instance_rel8d_ib_gib]
    assert hw_instance_rel8d_info[:rel8ns]["prop"] === [text_instance_ib_gib]
    assert hw_instance_rel8d_info[:rel8ns]["text"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:rel8ns]["prop_of"] === [hw_instance_rel8d_ib_gib]
  end

  @tag :capture_log
  test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    _ = Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(@test_identities_1, hw_ib)

    _ = Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    # {:ok, {hw_instance, _hw_instance_info, _hw_instance_ib_gib}} =
      # hw |> Expression.gib(:fork, @test_identities_1, hw_instance_ib)
    hw_instance = hw |> instance!(@test_identities_1, hw_instance_ib)

    _ = Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(@test_identities_1, text_ib)

    _ = Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    text_instance = text |> instance!(@test_identities_1, text_instance_ib)

    _ = Logger.debug "gonna rel8 'text property'"

    hw_instance =
      hw_instance |> rel8!(text_instance, @test_identities_1, ["text", "prop"], @default_transform_options)

    text_instance =
      text_instance |> rel8!(hw_instance, @test_identities_1, ["text_of", "prop_of"], @default_transform_options)

    # {hw_instance, text_instance} =
    #   hw_instance |> rel8!(text_instance, ["prop", "text"], ["prop_of"])
    hw_instance_info = hw_instance |> get_info!

    text_instance =
      text_instance |> mut8!(@test_identities_1, %{"content" => "Hello World!"})
    text_instance_info = text_instance |> get_info!

    _ = Logger.debug "hw_instance_info: #{inspect hw_instance_info}"
    _ = Logger.debug "text_instance_info: #{inspect text_instance_info}"
  end

  @tag :capture_log
  test "playground" do
    {:ok, root} = Expression.Supervisor.start_expression

    hw = root |> fork!(@test_identities_1, Helper.new_id)
    hw_info = hw |> get_info!
    _ = Logger.warn "hw_info: #{inspect hw_info}"

    hw_info[:rel8ns]["dna"] |> Enum.each(fn (ig) ->
        Logger.info "ig: #{ig}"
        {:ok, ig_pid} = Expression.Supervisor.start_expression(ig)
        ig_info = ig_pid |> Expression.get_info!
        Logger.info "ig_info: #{inspect ig_info}"
      end)

    # {hw, hwi} = hw |> instance!
    # hwi_info = hwi |> get_info!
    # _ = Logger.warn "hwi_info: #{inspect hwi_info}"
  end
end
