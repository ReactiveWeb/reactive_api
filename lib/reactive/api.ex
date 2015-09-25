defmodule Reactive.Api do
  def get_entity_id(contexts,context,module,args) do
    id=case context do
      :global -> [module | args]
      _c -> Reactive.Entity.request(contexts[context],{:get_context, context, module, args})
    end
    id
  end

  defp allow_observation(module,{what,auth_method},context) do
    quote do
      def exec([unquote(module)|id_args],{:observe,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:observe,unquote(what)]) do
          :allow -> Reactive.Entity.observe(id,what)
          error -> raise error
        end
      end
      def exec([unquote(module)|id_args],{:unobserve,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:observe,unquote(what)]) do
          :allow -> Reactive.Entity.unobserve(id,what)
          error -> raise error
        end
      end
      def exec([unquote(module)|id_args],{:get,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:observe,unquote(what)]) do
          :allow -> Reactive.Entity.get(id,what)
          error -> raise error
        end
      end
    end
  end

  defp allow_observation(module,what,context) do
    quote do
      def exec([unquote(module)|id_args],{:observe,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        Reactive.Entity.observe(id,what)
      end
      def exec([unquote(module)|id_args],{:observe,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        Reactive.Entity.unobserve(id,what)
      end
      def exec([unquote(module)|id_args],{:observe,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        Reactive.Entity.get(id,what)
      end
    end
  end

  defp allow_request(module,{type,auth_method},context) do
    quote do
      def exec([unquote(module)|id_args],{:request,args=[unquote(type) | _]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:request,args]) do
          :allow -> Reactive.Entity.request(id,{:api_request,args,contexts})
          error -> raise error
        end
      end
      def exec([unquote(module)|id_args],{:request,args=[unquote(type) | _],timeout},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:request,args]) do
          :allow -> Reactive.Entity.request(id,{:api_request,args,contexts},timeout)
          error -> raise error
        end
      end
    end
  end

  defp allow_request(module,type,context) do
    quote do
      def exec([unquote(module)|id_args],{:request,args=[unquote(type) | _]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        Reactive.Entity.request(id,{:api_request,args,contexts})
      end
      def exec([unquote(module)|id_args],{:request,args=[unquote(type) | _],timeout},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), id_args)
        Reactive.Entity.request(id,{:api_request,args,contexts},timeout)
      end
    end
  end

  defp allow_request_call(module,{type,auth_method},context) do
  #  IO.inspect({module,type,auth_method,context})
    quote do
      def exec([unquote(module)|id_args],{:request,aargs=[unquote(type) | args]},contexts) do
        id = get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:request,aargs]) do
          :allow -> apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|args]]])
          error -> raise error
        end
      end
      def exec([unquote(module)|id_args],{:request,aargs=[unquote(type) | args],timeout},contexts) do
        id = get_entity_id(contexts,unquote(context),unquote(module), id_args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts,:request,aargs]) do
          :allow -> apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|args]]])
          error -> raise error
        end
      end
    end
  end

  defp allow_request_call(module,type,context) do
    quote do
      def exec([unquote(module)|args],{:request,[unquote(type) | margs]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
      end
      def exec([unquote(module)|args],{:request,[unquote(type) | margs],timeout},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
      end
    end
  end

  defp allow_event(module,type,context) do
    quote do
      def exec([unquote(module)|args],{:event,args=[unquote(type) | _]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        Reactive.Entity.request(id,{:api_event,args})
      end
    end
  end

  defp allow_event_call(module,method,context) do
    quote do
      def exec([unquote(module)|args],{:event,margs=[unquote(method) | _]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        apply(module,:api_event,id|margs)
      end
    end
  end

  defp allow_gen(module,op,what,context) when is_list(what) do
    List.flatten(Enum.map(what, fn(w) -> allow_gen(module,op,w,context) end))
  end
  defp allow_gen(module,op,{what,auth_method},context) when is_list(what) do
    List.flatten(Enum.map(what, fn(w) -> allow_gen(module,op,{w,auth_method},context) end))
  end
  defp allow_gen(module,:observation,what,context) do
    [allow_observation(module,what,context)]
  end
  defp allow_gen(module,:request_call,method,context) do
    [allow_request_call(module,method,context)]
  end
  defp allow_gen(module,:event_call,method,context) do
    [allow_event_call(module,method,context)]
  end
  defp allow_gen(module,:request,type,context) do
    [allow_request(module,type,context)]
  end
  defp allow_gen(module,:event,type,context) do
    [allow_event(module,type,context)]
  end
  defp allow_gen(_module,:context,_context_name,_context) do
  end
  defp allow_gen(_module,:auth_method,_context_name,_context) do
  end

  defmacro allow(module,what) do
    context = what[:context] || :global
    auth = what[:auth_method] || :none
    case auth do
      :none -> {:__block__, [], List.flatten(Enum.map(what,fn({k,v})->allow_gen(module,k,v,context) end))}
      method -> {:__block__, [], List.flatten(Enum.map(what,fn({k,v})->allow_gen(module,k,{v,method},context) end))}
    end

  end

  defmacro __using__(_opts) do
    quote do
      require Reactive.Api
      import Reactive.Api

      def load_api do
      end

      def observe(id,what,contexts) do
        exec(id,{:observe,what},contexts)
      end
      def unobserve(id,what,contexts) do
        exec(id,{:unobserve,what},contexts)
      end
      def get(id,what,contexts) do
        exec(id,{:get,what},contexts)
      end
      def request(id,type,args,contexts) do
        exec(id,{:request,[type|args]},contexts)
      end
      def request(id,type,args,timeout,contexts) do
        exec(id,{:request,[type|args],timeout},contexts)
      end
      def event(id,type,args,contexts) do
        exec(id,{:event,[type|args]},contexts)
      end
    end
  end

end
