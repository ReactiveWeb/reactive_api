defmodule Reactive.Api do

  defp allow_observation(module,{what,auth_method}) do
    quote do
      def exec(id=[unquote(module)|args],{:observe,what=unquote(what)},contexts) do
        case apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.observe(id,what)
        else
          raise :not_allowed
        end
      end
      def exec(id=[unquote(module)|args],{:unobserve,what=unquote(what)},contexts) do
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.unobserve(id,what)
        else
          raise :not_allowed
        end
      end
      def exec(id=[unquote(module)|args],{:get,what=unquote(what)},contexts) do
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:observe,unquote(what)]) do
          :allow -> Reactive.Entity.get(id,what)
          error -> raise error
        end
      end
    end
  end

  defp allow_observation(module,what) do
    quote do
      def exec(id=[unquote(module)|args],{:observe,what=unquote(what)},contexts) do
        Reactive.Entity.observe(id,what)
      end
      def exec(id=[unquote(module)|args],{:unobserve,what=unquote(what)},contexts) do
        Reactive.Entity.unobserve(id,what)
      end
      def exec(id=[unquote(module)|args],{:get,what=unquote(what)},contexts) do
        Reactive.Entity.get(id,what)
      end
    end
  end

  defp allow_request(module,{type,auth_method}) do
    quote do
      def exec(id=[unquote(module)|margs],{:request,args=[unquote(type) | _]},contexts) do
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.request(id,{:api_request,args,contexts})
        else
          raise :not_allowed
        end
      end
      def exec(id=[unquote(module)|margs],{:request,args=[unquote(type) | _],timeout},contexts) do
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.request(id,{:api_request,args,contexts},timeout)
        else
          raise :not_allowed
        end
      end
    end
  end

  defp allow_request(module,type) do
    quote do
      def exec(id=[unquote(module)|margs],{:request,args=[unquote(type) | _]},contexts) do
        Reactive.Entity.request(id,{:api_request,args,contexts})
      end
      def exec(id=[unquote(module)|margs],{:request,args=[unquote(type) | _],timeout},contexts) do
        Reactive.Entity.request(id,{:api_request,args,contexts},timeout)
      end
    end
  end

  defp allow_request_call(module,{type,auth_method}) do
    quote do
      def exec(id=[unquote(module)|args],{:request,[unquote(type) | margs]},contexts) do
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
        else
          raise :not_allowed
        end
      end
      def exec(id=[unquote(module)|args],{:request,[unquote(type) | margs],timeout},contexts) do
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
        else
          raise :not_allowed
        end
      end
    end
  end

  defp allow_request_call(module,type) do
    quote do
      def exec(id=[unquote(module)|args],{:request,[unquote(type) | margs]},contexts) do
        apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
      end
      def exec(id=[unquote(module)|args],{:request,[unquote(type) | margs],timeout},contexts) do
        apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
      end
    end
  end

  defp allow_event(module,type) do
    quote do
      def exec(id=[unquote(module)|args],{:event,args=[unquote(type) | _]},contexts) do
        Reactive.Entity.request(id,{:api_event,args})
      end
    end
  end

  defp allow_event_call(module,method) do
    quote do
      def exec(id=[unquote(module)|args],{:event,margs=[unquote(method) | _]},contexts) do
        apply(module,:api_event,id|margs)
      end
    end
  end

  defp allow_gen(module,op,what) when is_list(what) do
    List.flatten(Enum.map(what, fn(w) -> allow_gen(module,op,w) end))
  end
  defp allow_gen(module,:observation,what) do
    [allow_observation(module,what)]
  end
  defp allow_gen(module,:request_call,method) do
    [allow_request_call(module,method)]
  end
  defp allow_gen(module,:event_call,method) do
    [allow_event_call(module,method)]
  end
  defp allow_gen(module,:request,type) do
    [allow_request(module,type)]
  end
  defp allow_gen(module,:event,type) do
    [allow_event(module,type)]
  end
  defp allow_gen(_module,:context,_context_name) do
  end
  defp allow_gen(_module,:atoms,_atoms_list) do
  end

  defmacro allow(module,what) do
    {:__block__, [], List.flatten(Enum.map(what,fn({k,v})->allow_gen(module,k,v) end))}
  end

  defmacro __using__(_opts) do
    quote do
      require Reactive.Api
      import Reactive.Api

      def load_api do
      end

      def observe([mod|margs],what,contexts) do
        moda=:erlang.binary_to_existing_atom("Elixir."<>mod,:utf8)
        wha=:erlang.binary_to_existing_atom(what,:utf8)
        exec([moda|map_args(margs)],{:observe,wha},contexts)
      end
      def unobserve([mod|margs],what,contexts) do
        moda=:erlang.binary_to_existing_atom("Elixir."<>mod,:utf8)
        wha=:erlang.binary_to_existing_atom(what,:utf8)
        exec([moda|map_args(margs)],{:unobserve,wha},contexts)
      end
      def get([mod|margs],what,contexts) do
        moda=:erlang.binary_to_existing_atom("Elixir."<>mod,:utf8)
        wha=:erlang.binary_to_existing_atom(what,:utf8)
        exec([moda|map_args(margs)],{:get,what},contexts)
      end
      def request([mod|margs],method,args,contexts) do
        moda=:erlang.binary_to_existing_atom("Elixir."<>mod,:utf8)
        mta=:erlang.binary_to_existing_atom(method,:utf8)
        exec([moda|map_args(margs)],{:request,[mta|args]},contexts)
      end
      def request([mod|margs],method,args,timeout,contexts) do
        moda=:erlang.binary_to_existing_atom("Elixir."<>mod,:utf8)
        mta=:erlang.binary_to_existing_atom(method,:utf8)
        exec([moda|map_args(margs)],{:request,[mta|args],timeout},contexts)
      end
      def event([mod|margs],method,args,contexts) do
        moda=:erlang.binary_to_existing_atom("Elixir."<>mod,:utf8)
        mta=:erlang.binary_to_existing_atom(method,:utf8)
        exec([moda|map_args(margs)],{:event,[mta|args]},contexts)
      end
      def map_notification({:notify,[module|margs],what,{signal,args}}) do
        << "Elixir." , ms :: binary >> = :erlang.atom_to_binary(module,:utf8) 
        {:notify,[ms|margs],what,{signal,args}}
      end
      defp map_args(args) do
        Enum.map(args,fn
          (x = ("Elixir." <> name)) -> :erlang.binary_to_existing_atom(x,:utf8)
          (x) -> x
        end)
      end
    end
  end

end
