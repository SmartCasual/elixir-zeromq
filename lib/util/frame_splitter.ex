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
  Returns `{:ok, flags, frame_blob}` if the full frame is available,
  otherwise requests more data by returning `{:ok, :more}`.
  """
  def add_binary(splitter, blob) do
    GenServer.call(splitter, {:add_binary, blob})
  end

  @doc """
  Returns the oldest frame body and flags as `{:ok, flags, frame_body, remaining_count}`
  if available, otherwise returns `:empty`.
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
    case :queue.out(frame_bodies) do
      {{:value, frame_body_and_flags}, frame_bodies} ->
        {:reply, {:ok, frame_body_and_flags, :queue.len(frame_bodies)}, {size, flags, stream, frame_bodies}}
      {:empty, frame_bodies} ->
        {:reply, :empty, {size, flags, stream, frame_bodies}}
    end
  end

  defp extract_frame_body(flags, size, stream, frame_bodies) do
    if size == nil || flags == nil do
      working_parts = ZeroMQ.Frame.extract_flags_and_size(stream)
    else
      working_parts = {flags, size, stream}
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
