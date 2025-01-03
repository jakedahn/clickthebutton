defmodule Clickthebutton.GameServerTest do
  use ExUnit.Case, async: false
  require Logger

  alias Clickthebutton.GameServer

  @save_path "priv/game_state_test.dat"

  setup do
    # Clean up any existing test file
    cleanup_test_file()

    # Reset the ETS table instead of restarting the GenServer
    :ets.delete_all_objects(:ctb_game_state)

    :ok
  end

  describe "score management" do
    test "increments score for new user" do
      assert GameServer.get_score("user1") == 0
      assert {:ok, 1} = GameServer.increment_score("user1", %{username: "test1"})
      assert GameServer.get_score("user1") == 1
    end

    test "increments existing score" do
      GameServer.increment_score("user2", %{username: "test2"})
      GameServer.increment_score("user2", %{username: "test2"})
      assert GameServer.get_score("user2") == 2
    end

    test "handles multiple users" do
      GameServer.increment_score("user3", %{username: "test3"})
      GameServer.increment_score("user4", %{username: "test4"})
      GameServer.increment_score("user3", %{username: "test3"})

      assert GameServer.get_score("user3") == 2
      assert GameServer.get_score("user4") == 1
    end

    test "throttles users exceeding click rate limit" do
      # Simulate rapid clicking
      user_id = "throttle_test_user"
      username = %{username: "throttle_test"}

      # Send 26 clicks (over the 25/sec limit)
      results =
        for _i <- 1..26 do
          GameServer.increment_score(user_id, username)
        end

      # The first 25 should succeed, the 26th should throttle
      assert Enum.count(results, fn
               {:ok, _} -> true
               _ -> false
             end) == 25

      assert List.last(results) |> elem(0) == :throttled

      # Verify score was reset to 0
      assert GameServer.get_score(user_id) == 0

      # Verify user is still throttled
      assert {:throttled, _until} = GameServer.increment_score(user_id, username)
    end

    test "allows clicking again after throttle period" do
      user_id = "throttle_recovery_user"
      username = %{username: "recovery_test"}

      # Trigger throttling
      for _i <- 1..26 do
        GameServer.increment_score(user_id, username)
      end

      # Fast forward time by manipulating the throttle check
      future_time = System.system_time(:millisecond) + :timer.minutes(1) + 100

      # This is a bit hacky for testing, but we'll directly manipulate the throttled_users map
      send(GameServer, {:test_set_time, future_time})

      # Should be able to click again
      assert {:ok, 1} = GameServer.increment_score(user_id, username)
    end

    test "maintains throttle across multiple click attempts" do
      user_id = "persistent_throttle_user"
      username = %{username: "persistent_test"}

      # Trigger throttling
      for _i <- 1..26 do
        GameServer.increment_score(user_id, username)
      end

      # Try clicking several times while throttled
      results =
        for _i <- 1..5 do
          GameServer.increment_score(user_id, username)
        end

      # All attempts should be throttled
      assert Enum.all?(results, fn
               {:throttled, _} -> true
               _ -> false
             end)
    end
  end

  describe "leaderboard" do
    test "returns sorted leaderboard" do
      # Create some scores
      GameServer.increment_score("user5", %{username: "test5"})
      GameServer.increment_score("user5", %{username: "test5"})
      GameServer.increment_score("user6", %{username: "test6"})
      GameServer.increment_score("user7", %{username: "test7"})
      GameServer.increment_score("user7", %{username: "test7"})
      GameServer.increment_score("user7", %{username: "test7"})

      leaderboard = GameServer.get_leaderboard()
      assert length(leaderboard) > 0

      # Check sorting
      [{top_user, {top_score, _top_username}} | _rest] = leaderboard
      assert top_user == "user7"
      assert top_score == 3
    end

    test "limits leaderboard to top 100" do
      # Create more than 100 users
      for i <- 1..110 do
        user_id = "user#{i}"
        GameServer.increment_score(user_id, %{username: "test#{i}"})
      end

      leaderboard = GameServer.get_leaderboard()
      assert length(leaderboard) == 100
    end
  end

  describe "persistence" do
    test "saves and loads state" do
      # Create some initial state
      GameServer.increment_score("persist_user1", %{username: "test1"})
      GameServer.increment_score("persist_user1", %{username: "test1"})
      GameServer.increment_score("persist_user2", %{username: "test2"})

      # Force a save
      send(GameServer, :save_to_disk)
      # Give it time to save
      Process.sleep(500)

      # Simulate restart by sending init message
      send(GameServer, :reinit_for_test)
      # Give it time to load
      Process.sleep(500)

      # Verify state was restored
      assert GameServer.get_score("persist_user1") == 2
      assert GameServer.get_score("persist_user2") == 1
    end
  end

  describe "username uniqueness" do
    test "detects taken usernames" do
      GameServer.increment_score("user1", %{username: "TestUser"})
      assert GameServer.username_taken?("TestUser")
      # Case insensitive
      assert GameServer.username_taken?("testuser")
      refute GameServer.username_taken?("DifferentUser")
    end
  end

  # Helper functions
  defp cleanup_test_file do
    File.rm(@save_path)
  end
end
