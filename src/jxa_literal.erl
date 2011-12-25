%% -*- mode: Erlang; fill-column: 80; comment-column: 76; -*-
-module(jxa_literal).

-export([comp/3]).
-include_lib("joxa/include/joxa.hrl").

%%=============================================================================
%% Types
%%=============================================================================

%%=============================================================================
%% Public API
%%=============================================================================
-spec comp(jxa_path:state(), jxa_ctx:context(), term()) -> cerl:cerl().
comp(Path0, Ctx0, Symbol) when is_atom(Symbol) ->
    {_, {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                   jxa_ctx:annots(Ctx0)),
    cerl:ann_c_atom([Line], Symbol);
comp(Path0, Ctx0, Integer) when is_integer(Integer) ->
    {Type, {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                      jxa_ctx:annots(Ctx0)),
    case Type of
        integer ->
            cerl:ann_c_int([Line], Integer);
        char ->
            cerl:ann_c_char([Line], Integer)
    end;
comp(Path0, Ctx0, Float) when is_float(Float) ->
    {float, {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                       jxa_ctx:annots(Ctx0)),
    cerl:ann_c_float([Line], float);
comp(Path0, Ctx0, Element) when is_tuple(Element) ->
    {_, {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                   jxa_ctx:annots(Ctx0)),
    mk_tuple(Path0, Line, Ctx0, tuple_to_list(Element));
comp(Path0, Ctx0, Element) when is_list(Element) ->
    {Type, Idx = {Line, _}} = jxa_annot:get(jxa_path:path(Path0),
                                      jxa_ctx:annots(Ctx0)),
    case Type of
        list ->
            mk_list(Path0, Line, Ctx0, Element);
        string ->
            mk_string(Path0, Line, Ctx0, Element);
        _ ->
           ?JXA_THROW({invalid_literal, Idx})
    end.

%%=============================================================================
%% Internal Functions
%%=============================================================================
-spec mk_list(jxa_path:state(), non_neg_integer(),
                jxa_ctx:context(), list()) ->
                       cerl:cerl().
mk_list(_Path0, _Line, _Ctx0, []) ->
    cerl:c_nil();
mk_list(Path0, Line, Ctx0, [H | T]) ->
    cerl:ann_c_cons([Line], comp(jxa_path:add(Path0), Ctx0, H),
                    mk_list(jxa_path:incr(Path0), Line, Ctx0, T)).

-spec mk_tuple(jxa_path:state(), non_neg_integer(),
               jxa_ctx:context(), list()) ->
                      cerl:cerl().
mk_tuple(Path0, Line, Ctx0, Elements0) ->
    {_, Elements1} =
        lists:foldl(fun(Element, {Path1, Acc0}) ->
                            Acc1 = [comp(jxa_path:add(Path1), Ctx0, Element)
                                    | Acc0],
                            Path2 = jxa_path:incr(Path1),
                            {Path2, Acc1}
                    end, {Path0, []}, Elements0),
    cerl:ann_c_tuple([Line],
                     Elements1).

-spec mk_string(jxa_path:state(), non_neg_integer(),
                  jxa_ctx:context(), list()) ->
                         cerl:cerl().
mk_string(_Path0, Line, _Ctx0, String) ->
    cerl:ann_c_string([Line], String).
