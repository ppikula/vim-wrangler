#!/usr/bin/env escript
%% -*- erlang -*-
main(_) ->
    ErlInterfaceDir  = code:lib_dir('erl_interface') ++ "/bin/erl_call",
    io:format("~s~n", [ErlInterfaceDir]).

