defmodule IbGib.Expression.HelloWorldTest do
  use ExUnit.Case
  alias IbGib.{Expression, Helper}
  import IbGib.Expression
  require Logger

  @delim "^"

  @tag :capture_log
  test "hello world then fork instance, text then fork instance, relate" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(hw_ib)
    # hw_info = hw_thing |> Expression.get_info!
    # hw_ib_gib = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])

    Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw_instance} =
      hw |> Expression.fork(hw_instance_ib)
    hw_instance_info = hw_instance |> Expression.get_info!
    hw_instance_ib_gib = Helper.get_ib_gib!(hw_instance_info[:ib], hw_instance_info[:gib])

    Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, text_instance} =
      text |> Expression.fork(text_instance_ib)
    text_instance_info = text_instance |> Expression.get_info!
    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])

    Logger.debug "gonna rel8"
    {:ok, {hw_instance_rel8d, text_instance_rel8d}} =
      hw_instance |> Expression.rel8(text_instance)

    assert is_pid(hw_instance_rel8d)
    assert is_pid(text_instance_rel8d)

    assert hw_instance !== hw_instance_rel8d
    assert text_instance !== text_instance_rel8d

    hw_instance_rel8d_info = hw_instance_rel8d |> Expression.get_info!
    _hw_instance_rel8d_ib_gib = Helper.get_ib_gib!(hw_instance_rel8d_info[:ib], hw_instance_rel8d_info[:gib])
    Logger.debug "hw_instance_rel8d_info: #{inspect hw_instance_rel8d_info}"
    text_instance_rel8d_info = text_instance_rel8d |> Expression.get_info!
    _text_instance_rel8d_ib_gib = Helper.get_ib_gib!(text_instance_rel8d_info[:ib], text_instance_rel8d_info[:gib])
    Logger.debug "text_instance_rel8d_info: #{inspect text_instance_rel8d_info}"

    assert hw_instance_rel8d_info[:relations]["rel8d"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:relations]["rel8d"] === [hw_instance_ib_gib]
  end

  @tag :capture_log
  test "hello world then fork instance, text then fork instance, relate property" do

    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(hw_ib)
    # hw_info = hw_thing |> Expression.get_info!
    # hw_ib_gib = Helper.get_ib_gib!(hw_info[:ib], hw_info[:gib])

    Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw_instance} =
      hw |> Expression.fork(hw_instance_ib)
    hw_instance_info = hw_instance |> Expression.get_info!
    hw_instance_ib_gib = Helper.get_ib_gib!(hw_instance_info[:ib], hw_instance_info[:gib])

    Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, text_instance} =
      text |> Expression.fork(text_instance_ib)
    text_instance_info = text_instance |> Expression.get_info!
    text_instance_ib_gib = Helper.get_ib_gib!(text_instance_info[:ib], text_instance_info[:gib])

    Logger.debug "gonna rel8 'text property'"
    {:ok, {hw_instance_rel8d, text_instance_rel8d}} =
      hw_instance |> Expression.rel8(text_instance, ["prop", "text"], ["prop_of"])

    assert is_pid(hw_instance_rel8d)
    assert is_pid(text_instance_rel8d)

    assert hw_instance !== hw_instance_rel8d
    assert text_instance !== text_instance_rel8d

    hw_instance_rel8d_info = hw_instance_rel8d |> Expression.get_info!
    _hw_instance_rel8d_ib_gib = Helper.get_ib_gib!(hw_instance_rel8d_info[:ib], hw_instance_rel8d_info[:gib])
    Logger.debug "hw_instance_rel8d_info: #{inspect hw_instance_rel8d_info}"
    text_instance_rel8d_info = text_instance_rel8d |> Expression.get_info!
    _text_instance_rel8d_ib_gib = Helper.get_ib_gib!(text_instance_rel8d_info[:ib], text_instance_rel8d_info[:gib])
    Logger.debug "text_instance_rel8d_info: #{inspect text_instance_rel8d_info}"

    assert hw_instance_rel8d_info[:relations]["rel8d"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:relations]["rel8d"] === [hw_instance_ib_gib]
    assert hw_instance_rel8d_info[:relations]["prop"] === [text_instance_ib_gib]
    assert hw_instance_rel8d_info[:relations]["text"] === [text_instance_ib_gib]
    assert text_instance_rel8d_info[:relations]["prop_of"] === [hw_instance_ib_gib]
  end

  @tag :capture_log
  test "create expression, from scratch, hello world instance Thing with hello world text Thing" do
    {:ok, root} = Expression.Supervisor.start_expression()

    # Randomized to keep unit tests from overlapping.
    Logger.debug "gonna hw"
    hw_ib = "hw_#{RandomGib.Get.some_letters(5)}"
    {:ok, hw} = root |> Expression.fork(hw_ib)

    Logger.debug "gonna instance hw"
    hw_instance_ib = "hw instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, {hw_instance, _hw_instance_info, _hw_instance_ib_gib}} =
      hw |> Expression.gib(:fork, hw_instance_ib)

    Logger.debug "gonna text"
    # Randomized to keep unit tests from overlapping.
    text_ib = "text_#{RandomGib.Get.some_letters(5)}"
    {:ok, text} = root |> Expression.fork(text_ib)
    # text_info = text_thing |> Expression.get_info!
    # text_ib_gib = Helper.get_ib_gib!(text_info[:ib], text_info[:gib])

    Logger.debug "gonna instance text"
    text_instance_ib = "text instance_#{RandomGib.Get.some_letters(5)}"
    {:ok, {text_instance, _text_instance_info, _text_instance_ib_gib}} =
      text |> Expression.gib(:fork, text_instance_ib)

    Logger.debug "gonna rel8 'text property'"
    {
      :ok,
      {_hw_instance, hw_instance_info, _hw_instance_ib_gib},
      {text_instance, _text_instance_info, _text_instance_ib_gib}
    } =
      hw_instance |> Expression.gib(:rel8, text_instance, ["prop", "text"], ["prop_of"])

    {:ok, {_text_instance, text_instance_info, _text_instance_ib_gib}} =
      text_instance
      |> Expression.gib(:mut8, %{"content" => "Hello World!"})

    Logger.debug "hw_instance_info: #{inspect hw_instance_info}"
    Logger.debug "text_instance_info: #{inspect text_instance_info}"
  end

end
