defmodule Clickthebutton.GameServer do
  use GenServer
  require Logger

  @table_name :ctb_game_state
  # Save every 1 minute
  @save_interval :timer.seconds(5)
  @save_path Application.compile_env(:clickthebutton, :game_state_path, "priv/game_state.dat")
  @topic "game:scores"

  # New constants for throttling
  @max_clicks_per_second 25
  @throttle_duration :timer.minutes(1)
  @click_window :timer.seconds(1)

  # Add to your state
  defmodule State do
    defstruct [:table, :dirty, :click_timestamps, :throttled_users, test_time: nil]
  end

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def increment_score(user_id, %{username: username}) do
    GenServer.call(__MODULE__, {:increment, user_id, username})
  end

  def get_score(user_id) do
    GenServer.call(__MODULE__, {:get_score, user_id})
  end

  def get_leaderboard do
    GenServer.call(__MODULE__, :get_leaderboard)
  end

  def username_taken?(username) do
    GenServer.call(__MODULE__, {:username_taken?, username})
  end

  def is_throttled?(user_id) do
    GenServer.call(__MODULE__, {:is_throttled?, user_id})
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    # If we have persisted data, load it from disk.
    table =
      case File.exists?(@save_path) do
        true ->
          case :ets.file2tab(String.to_charlist(@save_path)) do
            {:ok, loaded_table} ->
              Logger.info("Loaded existing game state from disk")
              loaded_table

            {:error, reason} ->
              Logger.warning("Failed to load game state: #{inspect(reason)}")
              # If load fails, create new table
              :ets.new(@table_name, [:set, :named_table, :public])
          end

        false ->
          Logger.info("No existing game state found, starting fresh")
          :ets.new(@table_name, [:set, :named_table, :public])
      end

    schedule_save()

    {:ok,
     %State{
       table: table,
       dirty: false,
       click_timestamps: %{},
       throttled_users: %{}
     }}
  end

  @impl true
  def handle_call({:increment, user_id, username}, _from, state) do
    now = System.system_time(:millisecond)

    case check_throttle(user_id, now, state) do
      {:throttled, until} ->
        Phoenix.PubSub.broadcast(
          Clickthebutton.PubSub,
          @topic,
          {:user_throttled, user_id, until}
        )

        {:reply, {:throttled, until}, state}

      {:ok, new_state} ->
        # Existing increment logic
        new_score =
          case :ets.lookup(@table_name, user_id) do
            [{^user_id, {score, _}}] -> score + 1
            [] -> 1
          end
          |> tap(fn score -> :ets.insert(@table_name, {user_id, {score, username}}) end)

        Phoenix.PubSub.broadcast(
          Clickthebutton.PubSub,
          @topic,
          {:score_updated, user_id, new_score}
        )

        {:reply, {:ok, new_score}, %{new_state | dirty: true}}
    end
  end

  @impl true
  def handle_call({:get_score, user_id}, _from, state) do
    score =
      @table_name
      |> :ets.lookup(user_id)
      |> case do
        [{^user_id, {score, _username}}] -> score
        [] -> 0
      end

    {:reply, score, state}
  end

  @impl true
  def handle_call(:get_leaderboard, _from, state) do
    leaderboard =
      @table_name
      |> :ets.tab2list()
      |> Enum.sort_by(fn {_user_id, {score, _username}} -> score end, :desc)
      |> Enum.take(100)

    {:reply, leaderboard, state}
  end

  @impl true
  def handle_call({:username_taken?, username}, _from, state) do
    is_taken =
      @table_name
      |> :ets.tab2list()
      |> Enum.any?(fn {_user_id, {_score, existing_username}} ->
        String.downcase(existing_username) == String.downcase(username)
      end)

    {:reply, is_taken, state}
  end

  @impl true
  def handle_call({:is_throttled?, user_id}, _from, state) do
    now = System.system_time(:millisecond)

    is_throttled =
      case Map.get(state.throttled_users, user_id) do
        nil -> false
        until -> now < until
      end

    {:reply, is_throttled, state}
  end

  @impl true
  def handle_info(:save_to_disk, %{dirty: false} = state) do
    schedule_save()
    {:noreply, state}
  end

  @impl true
  def handle_info(:save_to_disk, state) do
    # Save ETS table to disk
    :ets.tab2file(@table_name, String.to_charlist(@save_path))
    Logger.info("Game state saved to disk")

    schedule_save()
    {:noreply, %{state | last_save: DateTime.utc_now(), dirty: false}}
  end

  defp schedule_save do
    Process.send_after(self(), :save_to_disk, @save_interval)
  end

  # NOTE: This is only used inside of tests to reset state.
  @impl true
  def handle_info(:reinit_for_test, state) do
    # Remove the existing named table so file2tab won't conflict
    :ets.delete(@table_name)

    case File.exists?(@save_path) do
      true ->
        case :ets.file2tab(String.to_charlist(@save_path)) do
          {:ok, loaded_table} ->
            Logger.info("Reloaded game state from disk for test: #{inspect(loaded_table)}")
            {:noreply, %{state | table: loaded_table}}

          {:error, reason} ->
            Logger.warning("Failed to reload game state for test: #{inspect(reason)}")
            new_table = :ets.new(@table_name, [:set, :named_table, :public])
            {:noreply, %{state | table: new_table}}
        end

      false ->
        Logger.info("No existing game state found during test reinit, starting fresh")
        new_table = :ets.new(@table_name, [:set, :named_table, :public])
        {:noreply, %{state | table: new_table}}
    end
  end

  # Test helper to manipulate time for throttle testing
  @impl true
  def handle_info({:test_set_time, time}, state) do
    {:noreply, %{state | test_time: time}}
  end

  # Helper functions
  defp check_throttle(user_id, now, state) do
    current_time = state.test_time || now

    case Map.get(state.throttled_users, user_id) do
      until when is_number(until) and until > current_time ->
        {:throttled, until}

      _ ->
        timestamps =
          Map.get(state.click_timestamps, user_id, [])
          |> Enum.filter(fn ts -> current_time - ts < @click_window end)
          |> Kernel.++([current_time])

        if length(timestamps) > @max_clicks_per_second do
          throttle_until = current_time + @throttle_duration

          new_state = %{
            state
            | throttled_users: Map.put(state.throttled_users, user_id, throttle_until),
              click_timestamps: Map.delete(state.click_timestamps, user_id)
          }

          # Reset score to 0 when throttled
          :ets.insert(@table_name, {user_id, {0, ""}})
          {:throttled, throttle_until}
        else
          new_state = %{
            state
            | click_timestamps: Map.put(state.click_timestamps, user_id, timestamps)
          }

          {:ok, new_state}
        end
    end
  end
end
