defmodule Example1 do
  # so we can use the nicer pattern matches, e.g. wx(event: {:whatever})
  require Wx
  use Bitwise
  require Logger

  # the @behaviour will warn you if you forget a callback
  # but elixirLS dialyzer will forever warn you about the @behaviour
  # @behaviour :wx_object

  def start_link(args \\ [], opts \\ []), do: :wx_object.start_link(__MODULE__, args, opts)

  def init(args) do
    title = Keyword.get(args, :title, "Frame")
    size = Keyword.get(args, :size, {800, 600})
    state = Keyword.get(args, :state, %{})

    wx = :wx.new()
    Process.flag(:trap_exit, true)
    frame = :wxFrame.new(wx, Wx.wxID_ANY(), title, size: size)
    :wxFrame.connect(frame, :close_window)

    {panel, panelSizer} = create_panel(frame)

    :wxFrame.setSizer(panel, panelSizer)
    Wx.Util.setClientAndMinSize(frame, :wxSizer.calcMin(panelSizer))

    :wxFrame.show(frame)
    {frame, state}
  end

  defp create_panel(parent) do
    panel = :wxPanel.new(parent)

    {input, inputSizer} = create_input_grid(panel)
    {_, buttonSizer} = create_button_row(panel, input)

    # main sizer contains input grid and button row
    {sizer, sizify}  = Wx.Util.sizifier(:wxBoxSizer.new(Wx.wxVERTICAL()), flag: Wx.wxALL, border: 5)
    sizify.(inputSizer)
    sizify.(buttonSizer)

    {panel, sizer}
  end

  defp create_input_grid(panel) do
      # 2 column grid with 1 row: label "Foo" and input
      {inputSizer, inputify} = Wx.Util.sizifier(:wxFlexGridSizer.new(2, gap: {5, 5}))
      :wxStaticText.new(panel, Wx.wxID_ANY(), "Foo") |> then(inputify)
      input = :wxTextCtrl.new(panel, Wx.wxID_ANY()) |> then(inputify)

      {input, inputSizer}
  end

  defp create_button_row(panel, input) do
      # buttons in a horizonal row
      {buttonSizer, buttonify} = Wx.Util.sizifier(:wxBoxSizer.new(Wx.wxHORIZONTAL()))
      okButton = :wxButton.new(panel, Wx.wxID_OK()) |> then(buttonify)
      cancelButton = :wxButton.new(panel, Wx.wxID_CANCEL()) |> then(buttonify)

      # event version, uncomment below for callbacks
      # event version can modify state
      :wxButton.connect(okButton, :command_button_clicked, userData: input)
      :wxButton.connect(cancelButton, :command_button_clicked)

      # :wxButton.connect(okButton, :command_button_clicked,
      #   callback: &button_callback/2,
      #   userData: input
      # )
      # :wxButton.connect(cancelButton, :command_button_clicked, callback: &button_callback/2)


      {[okButton, cancelButton], buttonSizer}
  end

  # constants because we can't use the functions in pattern matches
  @id_ok Wx.wxID_OK()
  @id_cancel Wx.wxID_CANCEL()

  # defp button_callback(Wx.wx(id: @id_ok, userData: input), _) do
  #   Logger.debug("OK button clicked: #{:wxTextCtrl.getValue(input)}")
  # end
  # defp button_callback(Wx.wx(id: @id_cancel), _) do
  #   Logger.debug("Cancel button clicked")
  # end

  def handle_event(Wx.wx(event: Wx.wxClose(type: :close_window)), state) do
    {:stop, :normal, state}
  end

  def handle_event(
        Wx.wx(id: @id_ok, event: Wx.wxCommand(type: :command_button_clicked), userData: input),
        state
      ) do
    Logger.debug("OK pressed: #{:wxTextCtrl.getValue(input)}")
    {:noreply, state}
  end

  def handle_event(
        Wx.wx(id: @id_cancel, event: Wx.wxCommand(type: :command_button_clicked)),
        state
      ) do
    Logger.debug("Cancel pressed")
    {:noreply, state}
  end

  def terminate(_, _) do
    :wx.destroy()
  end

  def main(_args), do: Wx.Util.showAndWait(__MODULE__, [title: "Example 1"], [])
end
