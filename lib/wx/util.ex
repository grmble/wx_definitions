defmodule Wx.Util do
  @spec setClientAndMinSize(frame, clientSize) :: :ok
        when frame: :wxWindow.wxWindow(), clientSize: {integer(), integer()}
  @doc ~S"""
  Set the client and min size for the window.

  `:wxFrame.setSizerAndFit/2` seems to not work when the frame
  has a single panel with an associated sizer.

  This takes a `{w, h}` client size e.g. obtained via
  `:wxSizer.calcMin/1` and sets the windows size
  and min size.  The min size is adjusted by
  the delta between client and actual size of the window.
  """
  def setClientAndMinSize(frame, clientSize) do
    :wxWindow.setClientSize(frame, clientSize)
    :wxWindow.setMinSize(frame, clientSizeToSize(frame, clientSize))
  end

  @spec clientSizeToSize(frame, clientSize) :: {integer(), integer()}
        when frame: :wxWindow.wxWindow(), clientSize: {integer(), integer()}
  @doc """
  Adjusts a client size for a window to work for size or minSize.

  I.e. it calculates the delta between the windows actual and client size,
  then increases the given clientSize by that delta.
  """
  def clientSizeToSize(window, {w, h}) do
    {dw, dh} = sizeClientDelta(window)
    {w + dw, h + dh}
  end

  defp sizeClientDelta(window) do
    {ww, wh} = :wxWindow.getSize(window)
    {cw, ch} = :wxWindow.getClientSize(window)
    {ww - cw, wh - ch}
  end

  @spec showAndWait(mod, args, opts) :: :ok
        when mod: atom(), args: list(), opts: list()
  @doc """
  Show the window then wait until the process goes down.

  Shows the window by calling `start_link` with `args` and `opts`
  in the given module. Then monitors the process and waits
  for it to terminate.
  """
  def showAndWait(mod, args \\ [], opts \\ []) do
    {:wx_ref, _, _, pid} = apply(mod, :start_link, [args, opts])
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, _, _, _} ->
        :ok
    end
  end

  @spec sizifier(sizer, options) :: {:wxSizer.wxSizer(), (any -> any)}
        when sizer: :wxSizer.wxSizer(),
             options: [
               {:proportion, integer}
               | {:flag, integer}
               | {:border, integer}
               | {:userData, :wx.wx_object()}
             ]
  @doc """
  Helper to add an window or spacer to a sizer.

  The item will be added to the sizer with the given options,
  then the original item is returned.
  """
  def sizifier(sizer, options \\ []) do
    {sizer,
     fn
       {w, h} ->
         :wxSizer.add(sizer, w, h, options)
         {w, h}

       window ->
         :wxSizer.add(sizer, window, options)
         window
     end}
  end
end
