defmodule ELM.User do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import ELM.User
      Module.register_attribute(__MODULE__, :main, accumulate: false)

      @before_compile ELM.User
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    ref = Module.get_attribute(env.module, :main)

    quote do
      def _main do
        unquote(ref)
      end
    end
  end

  @doc """
  A macro that sets up the entry point of user's scenario
  """
  defmacro main(name) when is_atom(name) do
    quote do
      Module.put_attribute(__MODULE__, :main, unquote(name))
    end
  end
end
