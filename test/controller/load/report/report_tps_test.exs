defmodule ELM.Load.Report.TransPerSecondTest do
  alias ELM.Load.Report.TransPerSecond, as: Report
  use ExUnit.Case, async: true
  doctest Report

  test "Transactions per second test" do
    assert Report.get_report_timeline(0, 0) == []

    Report.update_report([
      {0_500_000, "UserA", "login", :tran_completed, 112},
      {1_330_000, "UserA", "logout", :tran_completed, 23},
      {2_330_000, "UserA", "home", :tran_completed, 88},
      {4_970_000, "UserA", "login", :tran_completed, 12},
      {5_100_000, "UserA", "home", :tran_completed, 10},
      {5_130_000, "UserA", "login", :tran_completed, 233},
      {6_000_000, "UserA", "login", :tran_completed, 512}
    ])

    assert Report.get_report_timeline(0, 2) == [%{:x => 0, :y => 1}, %{:x => 1, :y => 1}]
    assert Report.get_report_timeline(1, 3) == [%{:x => 1, :y => 1}, %{:x => 2, :y => 1}]

    assert Report.get_report_timeline(1, 6) == [
             %{:x => 1, :y => 1},
             %{:x => 2, :y => 1},
             %{:x => 4, :y => 1},
             %{:x => 5, :y => 2}
           ]

    Report.update_report([
      {7_000_000, "UserA", "logout", :tran_completed, 1},
      {7_430_000, "UserA", "login", :tran_completed, 733},
      {7_600_000, "UserA", "login", :tran_completed, 34},
      {8_000_000, "UserA", "logout", :tran_completed, 67}
    ])

    Report.update_report([])

    assert Report.get_report_timeline_us(1_000_000, 8_000_000) == [
             %{:x => 1, :y => 1},
             %{:x => 2, :y => 1},
             %{:x => 4, :y => 1},
             %{:x => 5, :y => 2},
             %{:x => 6, :y => 1},
             %{:x => 7, :y => 3}
           ]

    assert Report.get_report_timeline(6, 9) == [
             %{:x => 6, :y => 1},
             %{:x => 7, :y => 3},
             %{:x => 8, :y => 1}
           ]

    Report.clear_report()

    assert Report.get_report_timeline(0, 10) == []
  end
end
