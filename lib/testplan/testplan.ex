defmodule TestPlan do
  import ELM.TestPlanFactory

  def test_postcard do
    user =
      pool("Postcard")
      |> produce(20, 60)
      |> hold_on(60)

    [user]
  end
end
