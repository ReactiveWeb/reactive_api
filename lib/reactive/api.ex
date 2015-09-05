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
      def exec([unquote(module)|args],{:observe,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        case apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.observe(id,what)
        else
          raise :not_allowed
        end
      end
      def exec([unquote(module)|args],{:unobserve,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.unobserve(id,what)
        else
          raise :not_allowed
        end
      end
    end
  end

  defp allow_observation(module,what,context) do
    quote do
      def exec([unquote(module)|args],{:observe,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        Reactive.Entity.observe(id,what)
      end
      def exec([unquote(module)|args],{:unobserve,what=unquote(what)},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        Reactive.Entity.unobserve(id,what)
      end
    end
  end

  defp allow_request(module,{type,auth_method},context) do
    quote do
      def exec([unquote(module)|margs],{:request,args=[unquote(type) | _]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), margs)
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.request(id,{:api_request,args,contexts})
        else
          raise :not_allowed
        end
      end
      def exec([unquote(module)|margs],{:request,args=[unquote(type) | _],timeout},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), margs)
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          Reactive.Entity.request(id,{:api_request,args,contexts},timeout)
        else
          raise :not_allowed
        end
      end
    end
  end

  defp allow_request(module,type,context) do
    quote do
      def exec([unquote(module)|margs],{:request,args=[unquote(type) | _]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), margs)
        Reactive.Entity.request(id,{:api_request,args,contexts})
      end
      def exec([unquote(module)|margs],{:request,args=[unquote(type) | _],timeout},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), margs)
        Reactive.Entity.request(id,{:api_request,args,contexts},timeout)
      end
    end
  end

  defp allow_request_call(module,{type,auth_method},context) do
    quote do
      def exec([unquote(module)|args],{:request,[unquote(type) | margs]},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
        else
          raise :not_allowed
        end
      end
      def exec([unquote(module)|args],{:request,[unquote(type) | margs],timeout},contexts) do
        id=get_entity_id(contexts,unquote(context),unquote(module), args)
        if apply(__MODULE__,unquote(auth_method),[id,contexts]) do
          apply(unquote(module),:api_request,[unquote(type)|[id|[contexts|margs]]])
        else
          raise :not_allowed
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

  defmacro allow(module,what) do
    context = what[:context] || :global
    {:__block__, [], List.flatten(Enum.map(what,fn({k,v})->allow_gen(module,k,v,context) end))}
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
