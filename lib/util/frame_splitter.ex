defmodule ZeroMQ.FrameSplitter do
  @moduledoc """
  A GenServer which when fed a stream of binaries
  will split out ZeroMQ frames and return the binary
  blob (without parsing into a Command or Message).
  """

  use GenServer

  @doc """
  Starts the splitter.
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Adds the provided binary blob to the current stream.
  Returns `{:ok, count_of_full_frames_ready}`.
  """
  def add_binary(splitter, blob) do
    GenServer.call(splitter, {:add_binary, blob})
  end

  @doc """
  Returns the (possibly empty) list of complete frame bodies and flags
  as `{:ok, [{flags, frame_body}, ..]}`.
  """
  def fetch(splitter) do
    GenServer.call(splitter, :fetch)
  end

  @doc """
  Initializes the state with a nil size & flags, the empty stream in progress
  and the list for parsed frame bodies.
  """
  def init(:ok) do
    {:ok, {nil, nil, <<>>, :queue.new}}
  end

  def handle_call({:add_binary, blob}, _from, {size, flags, stream, frame_bodies}) do
    stream = stream <> blob

    {flags, size, stream, frame_bodies} = extract_frame_body(flags, size, stream, frame_bodies)

    {:reply, {:ok, :queue.len(frame_bodies)}, {size, flags, stream, frame_bodies}}
  end

  def handle_call(:fetch, _from, {size, flags, stream, frame_bodies}) do
    {:reply, {:ok, :queue.to_list(frame_bodies)}, {size, flags, stream, :queue.new}}
  end

  defp extract_frame_body(flags, size, stream, frame_bodies) do
    working_parts =
      if size == nil || flags == nil do
        ZeroMQ.Frame.extract_flags_and_size(stream)
      else
        {flags, size, stream}
      end

    if working_parts == :error do
      if byte_size(stream) == 0 do
        {nil, nil, stream, frame_bodies}
      else
        {flags, size, stream, frame_bodies}
      end
    else
      {flags, size, stream} = working_parts

      if byte_size(stream) >= size do
        <<frame_body::binary-size(size), stream::binary>> = stream
        frame_bodies = :queue.in({flags, frame_body}, frame_bodies)

        extract_frame_body(nil, nil, stream, frame_bodies)
      else
        {flags, size, stream, frame_bodies}
      end
    end
  end
end
