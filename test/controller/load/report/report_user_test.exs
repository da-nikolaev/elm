defmodule ELM.Load.Report.ActiveUsersOverTimeTest do
  alias ELM.Load.Report.ActiveUsersOverTime, as: Report
  use ExUnit.Case, async: true
  doctest Report

  test "Active users over time test" do
    assert Report.get_report_timeline(0, 0) == []

    Report.update_report([
      {1_000_000, "UserA", :user_started},
      {2_200_000, "UserA", :user_stopped},
      {2_330_000, "UserA", :user_started},
      {2_970_000, "UserA", :user_started},
      {3_100_000, "UserA", :user_stopped},
      {3_130_000, "UserA", :user_started},
      {4_000_000, "UserA", :user_stopped},
      {5_000_000, "UserA", :user_stopped}
    ])

    assert Report.get_report_timeline(1, 2) == [%{:x => 1, :y => 1}]
    assert Report.get_report_timeline(1, 3) == [%{:x => 1, :y => 1}, %{:x => 2, :y => 2}]

    assert Report.get_report_timeline(1, 6) == [
             %{:x => 1, :y => 1},
             %{:x => 2, :y => 2},
             %{:x => 3, :y => 2},
             %{:x => 4, :y => 1},
             %{:x => 5, :y => 0}
           ]

    Report.update_report([
      {6_330_000, "UserA", :user_started},
      {6_970_000, "UserA", :user_started},
      {7_330_000, "UserA", :user_started},
      {7_970_000, "UserA", :user_started}
    ])

    Report.update_report([])

    assert Report.get_report_timeline_us(1_000_000, 7_000_000) == [
             %{:x => 1, :y => 1},
             %{:x => 2, :y => 2},
             %{:x => 3, :y => 2},
             %{:x => 4, :y => 1},
             %{:x => 5, :y => 0},
             %{:x => 6, :y => 2}
           ]

    assert Report.get_report_timeline(1, 8) == [
             %{:x => 1, :y => 1},
             %{:x => 2, :y => 2},
             %{:x => 3, :y => 2},
             %{:x => 4, :y => 1},
             %{:x => 5, :y => 0},
             %{:x => 6, :y => 2},
             %{:x => 7, :y => 4}
           ]

    Report.clear_report()

    assert Report.get_report_timeline(0, 6) == []
  end
end
