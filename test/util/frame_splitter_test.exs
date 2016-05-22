defmodule ZeroMQ.FrameSplitterTest do
  use ExUnit.Case, async: true

  setup do
    short_frame = <<0x00, 10, "0123456789">>
    long_frame = <<0x02, byte_size(loads_of_text)::8 * 8, loads_of_text::binary>>

    {:ok, splitter} = ZeroMQ.FrameSplitter.start_link

    {:ok,
      splitter: splitter,
      short_frame: short_frame,
      long_frame: long_frame,
    }
  end

  test "providing an exact frame", context do
    {:ok, 1} = ZeroMQ.FrameSplitter.add_binary(
      context[:splitter],
      context[:short_frame]
    )

    {:ok, [{flags, frame_body}]} = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert flags == %{
      command: false,
      long: false,
      more: false,
    }

    assert frame_body == "0123456789"
  end

  test "providing a long frame", context do
    {:ok, 1} = ZeroMQ.FrameSplitter.add_binary(
      context[:splitter],
      context[:long_frame]
    )

    {:ok, [{flags, frame_body}]} = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert flags == %{
      command: false,
      long: true,
      more: false,
    }

    assert frame_body == loads_of_text
  end

  test "providing a frame over multiple calls", context do
    <<first_part::binary-size(5), second_part::binary>> = context[:short_frame]

    {:ok, 0} = ZeroMQ.FrameSplitter.add_binary(context[:splitter], first_part)
    {:ok, 1} = ZeroMQ.FrameSplitter.add_binary(context[:splitter], second_part)

    {:ok, [{flags, frame_body}]} = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert flags == %{
      command: false,
      long: false,
      more: false,
    }

    assert frame_body == "0123456789"
  end

  test "providing multiple frames over multiple calls", context do
    {:ok, 1} = ZeroMQ.FrameSplitter.add_binary(context[:splitter], context[:short_frame])
    {:ok, 2} = ZeroMQ.FrameSplitter.add_binary(context[:splitter], context[:long_frame])

    {:ok,
      [
        {flags_1, frame_body_1},
        {flags_2, frame_body_2},
      ]
    } = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert flags_1 == %{
      command: false,
      long: false,
      more: false,
    }
    assert frame_body_1 == "0123456789"

    assert flags_2 == %{
      command: false,
      long: true,
      more: false,
    }
    assert frame_body_2 == loads_of_text
  end

  test "providing multiple frames over one call", context do
    combined_frames = context[:short_frame] <> context[:long_frame]
    {:ok, 2} = ZeroMQ.FrameSplitter.add_binary(context[:splitter], combined_frames)

    {:ok,
      [
        {flags_1, frame_body_1},
        {flags_2, frame_body_2},
      ]
    } = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert flags_1 == %{
      command: false,
      long: false,
      more: false,
    }
    assert frame_body_1 == "0123456789"

    assert flags_2 == %{
      command: false,
      long: true,
      more: false,
    }
    assert frame_body_2 == loads_of_text
  end

  test ".fetch returns an empty list if no completed frame bodies available", context do
    {:ok, list} = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert list == []
  end

  test ".fetch empties the stored messages when called", context do
    {:ok, 1} = ZeroMQ.FrameSplitter.add_binary(context[:splitter], context[:short_frame])
    {:ok, _list} = ZeroMQ.FrameSplitter.fetch(context[:splitter])
    {:ok, list} = ZeroMQ.FrameSplitter.fetch(context[:splitter])

    assert list == []
  end

  defp loads_of_text do
    """
    Sed posuere consectetur est at lobortis. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Nullam id dolor id nibh ultricies vehicula ut id elit. Nullam quis risus eget urna mollis ornare vel eu leo. Cras mattis consectetur purus sit amet fermentum.

    Cras mattis consectetur purus sit amet fermentum. Aenean lacinia bibendum nulla sed consectetur. Curabitur blandit tempus porttitor. Donec sed odio dui. Curabitur blandit tempus porttitor. Vestibulum id ligula porta felis euismod semper. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.

    Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Maecenas sed diam eget risus varius blandit sit amet non magna.

    Curabitur blandit tempus porttitor. Nullam quis risus eget urna mollis ornare vel eu leo. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Cras mattis consectetur purus sit amet fermentum. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Nullam quis risus eget urna mollis ornare vel eu leo.
    """
  end
end
