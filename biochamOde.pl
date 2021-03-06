% BIOCHAM system http://contraintes.inria.fr/BIOCHAM/
% Copyright 2003-2008, INRIA, Projet Contraintes
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
%
% GNU prolog file biochamOde.pl by Sylvain Soliman
 
% Exports BIOCHAM to ODE format (as defined in xppaut)
% and to LaTeX format
% Imports ODE as BIOCHAM rules

% for storing long names conversion
:-dynamic(ode_name/2).
% dimensionless parameters
:- dynamic(constant_param/1).

export_ode(F):-
   \+(atom(F)),!,
   write_line_col('Error'),
   write('Filename must be an atom, or be enclosed in simple quotes\n').

export_ode(F):-
   (
      sub_atom(F,_,_,0,'.ode')
   ->
      G=F
   ;
      atom_concat(F,'.ode',G)
   ),
   open(G, write, _, [alias(ode)]),
   assertz((portray('=<'(A,B)):- %FF to complete...
            write_term(ode,'<='(A,B),[portrayed(true)]))),

   retractall(ode_name(_,_)),
   format(ode,"# Model generated by BIOCHAM~n",[]),
   g_read(kplot_range,RANGE),
   (
      RANGE = 0
   ->
      TMAX = 20
   ;
      RANGE = [_,TMAX,_,_]
   ),
   format(ode,"@ total=~p,xlo=0,xhi=~p,meth=gear,~n",[TMAX,TMAX]),
   apply_kinetics(K,ML),
   do_conservation,
   remove_invariants(ML,_,ML2),
   compile_all(K,ML2,ExprList),     
   ode_parameters,
   get_all_initial_values(ML2,ConcList),
   ode_init(ConcList),
   ode_macros,
   ode_kinetics(ML2,ExprList),
   format(ode,"done~n",[]),
   
   retractall(portray('=<'(_,_))),
   close(ode).

% Kinetic expressions

ode_kinetics([],[]).

ode_kinetics([M|ML],[K|KL]):-
   ode_convert_molecule_name(M,MM),
   ode_kinetic(K,KK),
   format(ode,"d~w/dt = ~w~n",[MM,KK]),
   ode_kinetics(ML,KL).

% Molecule name translation, same as for SBML (i.e. concatenation)

ode_convert_molecule_name(A,B):-
   ode_name(A,B),!.

ode_convert_molecule_name(A,B):-
   sbml_convert_molecule_name(A,AA),
   atom_length(AA,N),
   (
      N>8
   ->
      (
         (
            (
               sub_atom(AA,0,8,_,AAA),
               for(I,0,9),
                  number_atom(I,II),
                  atom_concat(AAA,II,B),
                  \+(ode_name(_,B))
            )
         ;
            (
               sub_atom(AA,0,7,_,AAAA),
               for(I,10,99),
                  number_atom(I,II),
                  atom_concat(AAAA,II,B),
                  \+(ode_name(_,B))
            )
         ),
         !,
         format(ode,"# ~w is ~w~n",[B,A])
      )
   ;
      B = AA
   ),
   assertz(ode_name(A,B)).

% Parameters and macros

ode_parameters:-
   k_parameter(P,V),
   format(ode,"parameter ~w=~p~n",[P,V]),
	fail.

ode_parameters.

ode_macros:-
   k_macro(M,V),
   (
      M = [MM]
   ->
      true
   ;
      M = MM
   ),
   ode_kinetic(V,VV),
   format(ode,"!~w=~w~n",[MM,VV]),
   fail.

ode_macros.

% convert a kinetic expression

ode_kinetic(K,KK):-
   atomic(K),!,
   g_read(ode_tex_mode,T),
   (
      T>0
   ->
      tex_underscore(K,KK)
   ;
      KK=K
   ).

ode_kinetic([M],MM):-
   g_read(ode_tex_mode,T),
   (
      T>0
   ->
      tex_convert_molecule_name(M,MM)
   ;
      ode_convert_molecule_name(M,MM)
   ),!.

ode_kinetic(if C then E else F,A):-
   !,
   ode_kinetic(C,CC),
   ode_kinetic(E,EE),
   ode_kinetic(F,FF),
   g_read(ode_tex_mode,T),
   (
      T>0
   ->
      format_to_atom(A,"\\mbox{ if } ~w \\mbox{ then } ~w \\mbox{ else } ~w",[CC,EE,FF])
   ;
      format_to_atom(A,"if (~w) then (~w) else (~w)",[CC,EE,FF])
   ).

ode_kinetic(A/B,M):-
   g_read(ode_tex_mode,T),
   ode_kinetic(A,AA),
   ode_kinetic(B,BB),
   (
      T>0
   ->
      format_to_atom(M,"\\frac{~w}{~w}",[AA,BB])
   ;
      M=AA/BB
   ),!.
      
ode_kinetic(A*B,M):-
   g_read(ode_tex_mode,T),
   ode_kinetic(A,AA),
   ode_kinetic(B,BB),
   (
      T>0
   ->
      format_to_atom(M,"~w \\cdot ~w",[AA,BB])
   ;
      M=AA*BB
   ),!.
      
ode_kinetic(A^B,M):-
   g_read(ode_tex_mode,T),
   ode_kinetic(A,AA),
   ode_kinetic(B,BB),
   (
      (T>0,\+(atomic(BB)))
   ->
      format_to_atom(M,"~w^{~w}",[AA,BB])
   ;
      M=AA^BB
   ),!.
      
ode_kinetic(A =< B,C):-
   !,
   ode_kinetic(A,AA),
   ode_kinetic(B,BB),
   format_to_atom(C,"~w<=~w",[AA,BB]).

% ode_kinetic(A >= B,C):-
%    !,
%    ode_kinetic(A,AA),
%    ode_kinetic(B,BB),
%    format_to_atom(C,"~w>=~w",[AA,BB]).

ode_kinetic(A = B,C):-
   !,
   ode_kinetic(A,AA),
   ode_kinetic(B,BB),
   format_to_atom(C,"~w==~w",[AA,BB]).

% ode_kinetic(A < B,C):-
%    !,
%    ode_kinetic(A,AA),
%    ode_kinetic(B,BB),
%    format_to_atom(C,"~w<~w",[AA,BB]).
% 
% ode_kinetic(A > B,C):-
%    !,
%    ode_kinetic(A,AA),
%    ode_kinetic(B,BB),
%    format_to_atom(C,"~w>~w",[AA,BB]).

ode_kinetic(A and B,AA*BB):-
   !,
   ode_kinetic(A,AA),
   ode_kinetic(B,BB).

ode_kinetic(A,B):-
   A=..[F|L],
   ode_kinetic_rec(L,LL),
   B=..[F|LL].

ode_kinetic_rec([],[]).
ode_kinetic_rec([H|T],[HH|TT]):-
   ode_kinetic(H,HH),
   ode_kinetic_rec(T,TT).

% Initial state

ode_init([]).

ode_init([([M],C)|L]):-
   ode_convert_molecule_name(M,MM),
   format(ode,"init ~w=~p~n",[MM,C]),
   ode_init(L).


%%%% LaTeX

export_ode_latex(F):-
   \+(atom(F)),!,
   write_line_col('Error'),
   write('Filename must be an atom, or be enclosed in simple quotes\n').

export_ode_latex(F):-
	(sub_atom(F,_,_,0,'.tex') -> G=F ; atom_concat(F,'.tex',G)),
        open(G, write, _, [alias(tex)]),
   retractall(ode_name(_,_)),
   g_assign(ode_tex_mode,1),
   format(tex,"%% Equations generated by BIOCHAM~n",[]),
   apply_kinetics(K,ML),
   compile_all(K,ML,ExprList),     
   tex_kinetics(ML,ExprList),
   tex_macros,
   tex_parameters,
   get_all_initial_values(ML,ConcList),
   tex_init(ConcList),
   format(tex,"%% done~n",[]),
   g_assign(ode_tex_mode,0),
   close(tex).


% Molecule name conversion

tex_convert_molecule_name(A,B):-
   ode_name(A,B),!.

tex_convert_molecule_name(A,B):-
   sbml_convert_molecule_name(A,B1),
   tex_underscore(B1,B2),
   B=[B2],
   assertz(ode_name(A,B)).

% Kinetic expressions

tex_kinetics(L,M):-
  format(tex,"\\noindent~n$\\displaystyle~n",[]),
  tex_kinetics1(L,M).
  
tex_kinetics1([],[]):-
   format(tex,"$~n~n",[]).

tex_kinetics1([M|ML],[K|KL]):-
   tex_convert_molecule_name(M,MM),
   ode_kinetic(K,KK),
   format(tex,"\\frac{d~w}{dt} = ~w~n\\\\~n\\\\~n",[MM,KK]),
   tex_kinetics1(ML,KL).

% Parameters and macros

tex_parameters:-
   format(tex,"\\begin{tabular}{|l|l|}~n\\hline Parameter & Value\\\\\\hline~n",[]),
   tex_parameters1.

tex_parameters1:-
   k_parameter(P,V),
   tex_underscore(P,P1),
   format(tex,"\\hline~n$~w$ & $~p$\\\\~n",[P1,V]),
	fail.

tex_parameters1:-
   format(tex,"\\hline~n\\end{tabular}~n~n",[]).

tex_macros:-
  format(tex,"\\noindent~n$\\displaystyle~n",[]),
  tex_macros1.

tex_macros1:-
   k_macro(M,V),
   \+(M = [_]),
   tex_underscore(M,M1),
   ode_kinetic(V,VV),
   format(tex,"~w = ~w\\\\~n\\\\~n",[M1,VV]),
   fail.

tex_macros1:-
   format(tex,"$~n~n",[]).

% Initial state

tex_init(L):-
   format(tex,"\\begin{tabular}{|l|l|}~n\\hline Compound & Initial conc.\\\\\\hline~n",[]),
   tex_init1(L).

tex_init1([]):-
   format(tex,"\\hline~n\\end{tabular}~n~n",[]).

tex_init1([([M],C)|L]):-
   tex_convert_molecule_name(M,[MM]),
   format(tex,"\\hline~n$~w$ & $~p$\\\\~n",[MM,C]),
   tex_init1(L).

% Escape underscores for TeX

tex_underscore(A,B):-
   format_to_atom(M,"~w",[A]),
   tex_underscore1(M,B).

tex_underscore1(A,B):-
   sub_atom(A,I1,1,I2,'_'),!,
   sub_atom(A,0,I1,_,A1),
   sub_atom(A,_,I2,0,A2),
   tex_underscore1(A2,B2),
   atom_concat(A1,'\\_',B1),
   atom_concat(B1,B2,B).
   
tex_underscore1(A,A).

%%%%%%%%%%%%%%
% import_ode %
%%%%%%%%%%%%%%
% transforms a system of ode written in xppaut syntax
%    parameter k=E
%    !macro=E
%    dX/dt=f(X)
%    init X=E
% in a biocham reaction model over molecules X

% the sum of expressions E with integer coefficient C
% appearing in dV/dt is memorized in
% ode_product(E, C, V)
:- dynamic(ode_product/3).
:- dynamic(ode_parameter/1).
:- dynamic(ode_rule_merge/1).
:- dynamic(ode_rate/2).
:- dynamic(ode_rate_linear_expressions/2).
:- dynamic(ode_species/1).
:- dynamic(ode_macro/2).
:- dynamic(ode_linear_expression/1).
:- dynamic(ode_ghost/2).


load_ode(F):-
	clear_biocham,
        add_ode(F).

add_ode(F):-
   \+(atom(F)),!,
   write_line_col('Error'),
   write('Filename must be an atom, or be enclosed in simple quotes\n'),
   fail.

% Parameters and macros need to be read first not to be confused with molecules
add_ode(F):-
   (sub_atom(F,_,_,0,'.ode') -> G=F ; atom_concat(F,'.ode',G)),
   open(G, read, _, [alias(ode)]),
   retractall(ode_product(_,_,_)),
   retractall(ode_parameter(_)),
   retractall(ode_rule_merge(_)),
   retractall(ode_rate(_, _)),
   retractall(ode_species(_)),
   retractall(ode_macro(_,_)),
   format_debug(8, "parsing ode file...", []),
   catch(parse_ode,E,write('Error in parsing ODE '(E))),
   close(ode),
   !,
   recover_zombie_molecules,
   format_debug(8, "~nadding kinetics...", []),
   add_kinetics,
   format_debug(8, "~ngenerating biocham rules...", []),
   generate_biocham_rules,
   format_debug(8, "~nadding biocham rules...", []),
   add_biocham_rules,
   format_debug(8, "done.~N", []).


parse_ode:-
	repeat,
	skip_blank(C),
	(
           get_line(C,L)
	-> 
           parse_line(L),
           fail
	;
           !
        ).

skip_blank(C):-
	get_char(ode,B),
	(B=' ' -> skip_blank(C) ; C=B).

get_line(end_of_file,_):-	!,
	fail.
get_line('\n',['.']):- !.
get_line(C,[C|L]):-
	get_char(ode,D),
	get_line(D,L).

read_float_from_chars(Chars, Float) :-
   ode_add_dot(Chars, CharsD), %add_dot from biosyntax, modified to read from chars
   read_from_chars(CharsD, Float).

ode_add_dot([], []).
ode_add_dot(['.' | CL], ['.' | CL]) :- !.
ode_add_dot(['e' | CL], ['.', '0', 'e' | CL]) :- !.
ode_add_dot(['E' | CL], ['.', '0', 'E' | CL]) :- !.
ode_add_dot([C | CL1], [C | CL2]) :- ode_add_dot(CL1, CL2).

%FF not proud of it
xpp_translate([],[]).
xpp_translate(['<','='|L],['=','<'|R]):- !,
   xpp_translate(L,R).
xpp_translate([C|L],[C|R]):- 
   xpp_translate(L,R).

dotsplit_chars_using_char([Char|R], Char, ['.'], R):-!.
dotsplit_chars_using_char([C|LC], Char, [C|L], R):-
   dotsplit_chars_using_char(LC, Char, L, R).

parse_equalities(Line, [Eq | Eqs]) :-   
   dotsplit_chars_using_char(Line, ',', Left, Right)
   ->
   parse_equality(Left, Eq),
   parse_equalities(Right, Eqs)
   ;
   parse_equality(Line, Eq),
   Eqs = [].

parse_equality(Line, (X, E)) :-
   dotsplit_chars_using_char(Line, '=', Left, Right),
   read_term_from_chars(Left,X,[variable_names(VLN)]), substitute_varnames(VLN),
   read_float_from_chars(Right, E).
   

assert_parameters([]).
assert_parameters([P | Ps]) :-
   assert_parameter(P),
   assert_parameters(Ps).
assert_parameter((X, E)) :-   
   format_debug(8,"parsed xpp parameter ~w=~w~n",[X,E]),
   asserta(ode_parameter(X)),
   parameter(X,E).

assert_initials([]).
assert_initials([P | Ps]) :-
   assert_initial(P),
   assert_initials(Ps).
assert_initial((X, E)) :-
   format_debug(8,"parsing xpp initial state ~w=~w~n",[X,E]),
   assertset(ode_species(X)),   % needed so that macros get concentrations right
   present(X,E).                % initial state


parse_line([('#') | _]):-!.
parse_line([('@') | _]):-!.
parse_line(['!'|L]):-!,
   dotsplit_chars_using_char(L, '=',LL,LR),
   read_term_from_chars(LL,X,[variable_names(VLN)]),
   substitute_varnames(VLN),
   read_term_from_chars(LR,E,[variable_names(VRN)]),
   substitute_varnames(VRN),
   mark_species(E, Em),
   format_debug(8,"parsing xpp macro ~w=~w~n",[X, Em]),
   asserta(ode_macro(X,E)), % for use only in recover_ghost_molecules
   macro(X,Em).

parse_line(['p','a','r',' '|L]):- !,
   parse_equalities(L, Eqs),
   assert_parameters(Eqs).

parse_line(['p','a','r','a','m','e','t','e','r',' '|L]):-!,
   parse_equalities(L, Eqs),
   assert_parameters(Eqs).

parse_line(['i', 'n', 'i', 't', ' ' | L]) :- !,
   parse_equalities(L, Eqs),
   assert_initials(Eqs).

% aux is display only, we do not care
parse_line(['a', 'u', 'x', ' ' | _]):-
   !.

parse_line(L):-
	read_token_from_chars(L,done),
	!.
parse_line(L):-
        dotsplit_chars_using_char(L, '=',LL,LR),
        read_term_from_chars(LL,(DX/dt),[variable_names(VLN)]),
        substitute_varnames(VLN),
        xpp_translate(LR,LRR),
        read_term_from_chars(LRR,E,[variable_names(VRN)]),
        substitute_varnames(VRN),
	atom_concat(d,X,DX),
        !,
        format_debug(8,"parsing xpp ode d~w/dt=~w~n",[X,E]),
        asserta(ode_rate(E,X)),
        assertset(ode_species(X)).
parse_line(L):-
	atom_chars(T,L),
	last_read_start_line_column(R,_),
	format("~nSyntax error in load_ode line ~p: ~w~n",[R,T]),
	fail.

substitute_varnames([]).

substitute_varnames([V = V| L]) :-
   substitute_varnames(L).


%% substitute_in_rates(+SourcePattern, +TargetPattern)
%
% rewrite in all ode_rates SourcePattern into TargetPattern
substitute_in_rates(SPat, TPat) :-
   (
      retract(ode_rate(E, X)),
      rewrite_term(E, EE, SPat, TPat),
      assertz(ode_rate(EE, X)),
      fail
   ;
      true
   ).

% rewrite in all ode_rates SourcePattern into TargetPattern
substitute_all_in_rates(Substitutions) :-
   (
      retract(ode_rate(E, X)),
      rewrites_term(E, EE, Substitutions),
      assertz(ode_rate(EE, X)),
      fail
   ;
      true
   ).


normalize_kinetics(K, KK) :-
   !,
   factorize_parameters(K, KK),
   format_debug(8, "normalized ~w to ~w~n", [K, KK]).


factorize_parameters(K, KK) :-
   factorize_params_list(K, K1),
   format_debug(8, "factorized ~w to ~w~n", [K, K1]),
   recompose(K1, K2),
   simplify(K2, K3),
   prettify(K3, KK).


% list of tuples (Number, product of parameters as a list, the rest)

factorize_params_list(N, [(N, [], 1)]) :-
   number(N),
   !.

factorize_params_list(M, L) :-
   ode_macro(M, E),
   !,
   factorize_params_list(E, L).

factorize_params_list(K, [T]) :-
   k_parameter(K, _),
   !,
   (
      constant_param(K)
   ->
      T = (1, [], K)
   ;
      T = (1, [K], 1)
   ).

factorize_params_list(X + Y, L) :-
   !,
   factorize_params_list(X, L1),
   factorize_params_list(Y, L2),
   sum_params_list(L1, L2, L).

factorize_params_list(X - Y, L) :-
   !,
   factorize_params_list(X, L1),
   factorize_params_list(Y, L2),
   negate_params_list(L2, L3),
   sum_params_list(L1, L3, L).

factorize_params_list(-Y, L) :-
   !,
   factorize_params_list(Y, L1),
   negate_params_list(L1, L).

factorize_params_list(X * Y, L) :-
   !,
   factorize_params_list(X, L1),
   factorize_params_list(Y, L2),
   mult_params_list(L1, L2, L).

factorize_params_list(X / Y, L) :-
   !,
   factorize_params_list(X, L1),
   (
      factorize_params_list(Y, [(N, K, T)])
   ->
      div_params_list_param(L1, (N, K, T), L)
   ;
      div_params_list_param(L1, (1, [], Y), L)
   ).

factorize_params_list(F, [(1, [], F)]).


negate_params_list([], []).

negate_params_list([(N, K, T)], [(M, K, T)]) :-
   M is -N.

negate_params_list([H1, H2 | T], [HH1 | TT]) :-
   negate_params_list([H1], [HH1]),
   negate_params_list([H2 | T], TT).


sum_params_list([], L, L).

sum_params_list([(N, K, T) | L1], L2, [E | L]) :-
   (
      select((M, K, U), L2, L3)
   ->
      (
         M < 0
      ->
         MM is -M,
         E = (1, K, N * T - MM * U)
      ;
         E = (1, K, N * T + M * U)
      ),
      sum_params_list(L1, L3, L)
   ;
      E = (N, K, T),
      sum_params_list(L1, L2, L)
   ).


mult_params_list([], _, []).

mult_params_list([H | T], L, LL) :-
   mult_params_list_param(L, H, L1),
   mult_params_list(T, L, L2),
   sum_params_list(L1, L2, LL).


mult_params_list_param([], _, []).

mult_params_list_param([(N, K, T) | L], (M, J, U), [(O, KK, T * U) | LL]) :-
   O is N * M,
   append(K, J, KKK),
   sort(KKK, KK),
   mult_params_list_param(L, (M, J, U), LL).


div_params_list_param([], _, []).

div_params_list_param([(N, K, T) | L], (M, [], U), [H | LL]):-
   !,
   O is N / M,
   H = (O, K, T / U),
   div_params_list_param(L, (M, [], U), LL).

div_params_list_param([(N, K, T) | L], (M, [J], U), [H | LL]):-
   select(J, K, KK),
   !,
   O is N / M,
   H = (O, KK, T / U),
   div_params_list_param(L, (M, [J], U), LL).

div_params_list_param([(N, K, T) | L], (M, J, U), [H | LL]):-
   O is N / M,
   build_prod(J, P),
   H = (O, K, T / (P * U)),
   div_params_list_param(L, (M, J, U), LL).


recompose(L, P) :-
   reverse(L, LL),
   recompose_aux(LL, P).

recompose_aux([], 0).

recompose_aux([(N, P, T)], N*PP*T) :-
   build_prod(P, PP).

recompose_aux([H1, H2 | T], K) :-
   recompose_aux([H1], N*P1*P2),
   recompose_aux([H2 | T], KK),
   (
      N < 0
   ->
      M is -N,
      K = KK - M * P1 * P2
   ;
      K = KK + N * P1 * P2
   ).


build_prod([], 1).
build_prod([X], X).
build_prod([X, Y | L], X * P) :-
   build_prod([Y | L], P).


mysubterm(A, A).

mysubterm(A,B):-
   compound(B),
   B =.. [_|T],
   mysubtermrec(A,T).

mysubtermrec(A,[H|T]):-
   (
      mysubterm(A,H)
   ;
      mysubtermrec(A,T)
   ).


extract_ghost(From, Ghost, E, RateSubstitutions, GhostRate, Expression) :-
   From = rate(Rates),
   Expression = C - X - Y,
   format_debug(8, "looking for ghost of form ~w in ~w~n", [Expression, E]),
   mysubterm(Expression, E),
   format_debug(
      8,
      "found! checking constants and molecules in ~w~n",
      [Expression]
   ),
   (
      number(C)
   ;
      k_parameter(C, _)
   ),
   ode_species(X),
   ode_species(Y),
   (
      ode_rate(RX, X)
   ;
      member((X, RX), Rates)
   ),
   !,
   (
      ode_rate(RY, Y)
   ;
      member((Y, RY), Rates)
   ),
   !,
   GhostRate = - RX - RY,
   RateSubstitutions  = [
      (C - X - Y      , Ghost),
      (C + (J - X - Y) , J + Ghost),
      ((J + C) - X - Y , J + Ghost),
      ((C + J) - X - Y , J + Ghost),
      ((J - C) + X + Y , J - Ghost)
   ].



extract_ghost(From, Ghost, E, RateSubstitutions, GhostRate, Expression) :-
   From = rate(Rates),
   Expression = C - X,
   format_debug(8, "looking for ghost of form ~w in ~w~n", [Expression, E]),
   mysubterm(Expression, E),
   format_debug(8, "found! checking constants and molecules in ~w~n",
      [Expression]),
   (number(C);k_parameter(C, _)),
   ode_species(X),
   ((ode_rate(RX, X) ; member((X, RX), Rates)) -> GhostRate = -RX),
   RateSubstitutions  = [
      (C - X      , Ghost),
      (C + (J - X) , J + Ghost),
      ((J + C) - X , J + Ghost),
      ((C + J) - X , J + Ghost),
      ((J - C) + X , J - Ghost)
   ].


make_ghost_name(M, Index, Ghost1) :-
   atom_concat(M, '__ghost', Ghost),
   number_atom(Index, AIndex),
   atom_concat(Ghost, AIndex, Ghost1).



%% recover_zombie_molecules
%
% search for K - X expressions in ode_rates and create adequate ghost
recover_zombie_molecules :-
   % need dimensions of parameters
   retractall(constant_param(_)),
   findall(R, (ode_rate(RR, _), mark_species(RR, R)), LR),
   findall((_ - P), k_parameter(P, _), Ldim),
   g_read(no_dim_output, NDO),
   g_assign(no_dim_output, 1),
   (
      find_parameter_dim_rec(LR, Ldim),
      !,
      \+ (
         member(V-K, Ldim),
         V == 100,
         assertz(constant_param(K)),
         fail
      )
   ;
      true
   ),
   g_assign(no_dim_output, NDO),

   findall(
      (X, NE),
      (
         retract(ode_rate(E, X)),
         normalize_kinetics(E, NE)
      ),
      LM
   ),
   format_debug(8, "list of normalized kinetics ~w~n", LM),
   recover_zombie_molecules(LM, 1).


%% recover_zombie_molecules(+ListOfMacros)
%
% for each pair (Name, Expression), search 'K - X' in the expression
% if not found, rate is clean -> assert and continue
% if found, declare ghost and rewrite in yet unseen ode_rates
recover_zombie_molecules([(X, E) | LM], N) :-
   make_ghost_name(X, N, Ghost),
   (
      extract_ghost(rate([(X, E) | LM]), Ghost, E, RateSubstitutions, GhostRate, Expression)
   ->
      (
         format("Found ghost molecule in rate : ~w with expression ~w~N", [Ghost, Expression]),
         asserta(ode_species(Ghost)),
         (
            retract(ode_rate(X0, E0)),
            rewrites_term(E0, NE0, RateSubstitutions),
            assertz(ode_rate(X0, NE0)),
            fail
         )
      ;
         rewrites_term([(X, E), (Ghost, GhostRate) | LM], LLM, RateSubstitutions),
         N1 is N + 1, recover_zombie_molecules(LLM, N1)
      )
   ;
      assertz(ode_rate(E, X)),
      recover_zombie_molecules(LM, 1)
   ).

recover_zombie_molecules([], _).





%transforms ode_rates in ode_products
recover_ghost_molecules :-
   retract(ode_rate(E, X)),
   exhibit_linear_expressions(E, CLE),
%   format("Transformed~n~w~nin~n~w~n", [E, CLE]),
   asserta(ode_rate_linear_expressions(CLE, X)),
   fail
   ;

   retract(ode_macro(X, E)),
   exhibit_linear_expressions(E, _),
%   format("Transformed~n~w~nin~n~w~n", [E, CLE]),
   fail
   ;

   findall(LE, ode_linear_expression(LE), LES),
   sort(LES, SortedLES),
   filter_linear_expressions(SortedLES, FLES),
   
%   format("Linear expressions :~n", []), findall(LE, ( member(LE, FLES), format("~w~n", [LE]) ), _),
   
   powersplit(FLES, SplitLES),
%   format("split expressions, filtering...~N", []),
   filter_linear_expressions(SplitLES, FSplitLES),

%   format("Split linear expressions:~n", []), findall(L, ( member(L, FSplitLES), format("~w~n", [L]) ), _),

   member(LE, FSplitLES),
   ( (
      member((Pos, P), LE), 
      P > 0,
      atom(Pos)
      ;
      member((Pos, P), LE), 
      P < 0,
      atom(Pos)
     )
   -> true),
   atom_concat(Pos, '__ghost', Ghost),
   format("Found ghost molecule : ~w with coefficients ~w~n", [Ghost, LE]),
   asserta(ode_ghost(Ghost, LE)),
   asserta(ode_species(Ghost)),
   fail
   ;
   substitute_ghosts.


substitute_ghosts :-
   findall(GhostLE, (ode_ghost(Ghost, LE), GhostLE = (Ghost, LE)), GhostLEs),
   retract(ode_rate_linear_expressions(LE, X)),
   substitute_ghosts(LE, GhostLEs, SLE),
   inhibit_linear_expressions(SLE, ISLE),
   asserta(ode_rate(ISLE, X)),
   fail
   ;
   ode_ghost(Ghost, LE),
   compute_ghost_rate(LE, Rate),   
%   format("Molecule ~w with LE ~w has rate~n~w~n", [Ghost, LE, Rate]),
   asserta(ode_rate(Rate, Ghost)),
   fail
   ;
   true.


compute_ghost_rate(LE, Rate) :-
   findall((SRate, Coef), (member((Species, Coef), LE),
                           ode_species(Species),!,
                           ode_rate(SRate, Species)),
           SRateCoefs),   
   svector2le(SRateCoefs, Rate).


substitute_ghosts(svector(L), GLs, svector(LR)) :- !,
   substitute_ghosts_in_svector(GLs, L, LR).

substitute_ghosts(T, GLs, TR) :-
   T =.. [Op | Args],
   substitute_ghosts_list(Args, GLs, SArgs),
   TR =.. [Op | SArgs].

substitute_ghosts_list([], _, []).
substitute_ghosts_list([Arg | Args], GLs, [SArg | SArgs]) :-
   substitute_ghosts(Arg, GLs, SArg),
   substitute_ghosts_list(Args, GLs, SArgs).

substitute_ghosts_in_svector([], L, L).
substitute_ghosts_in_svector([(Ghost, LE) | GLEs], SVector, SVectorR) :-
   (
      list_inclusion(LE, SVector)
   ->
      svector_minus(SVector, LE, SVector0),
      svector_sum([SVector0, [(Ghost,1)]], SVector1)
      ;
      SVector1 = SVector
   ),      
   substitute_ghosts_in_svector(GLEs, SVector1, SVectorR).


filter_linear_expressions(LES, FLES) :-   
   findall(LE, (
                  member(LE, LES),
                  length(LE, NLE),
                  NLE > 1,
                  % must have one positive and one negative member
                  ( (member((_, NegCoef), LE), NegCoef < 0) -> true ),
                  ( (member((_, PosCoef), LE), PosCoef > 0) -> true ),
                  % must have one species and one parameter/constant = non-species
                  ( (member((M1, _), LE), ode_species(M1)) -> true ),
                  ( (member((M2, _), LE), (\+ ode_species(M2))) -> true ),
                  % if there is a constant, it must be 1
                  ( ( member((C, _), LE), number(C), C \= 1, C \= 1.0 ) -> fail ; true ),
                  true
               ),
           FLES).


list_inclusion([], _).
list_inclusion([E | Es], [F | Fs]) :-
   (
      E @< F
   ->
      fail
   ;
      E = F
   ->
      list_inclusion(Es, Fs)
   ;
      list_inclusion([E | Es], Fs)
   ).


svector2le([], 0).
svector2le([(M, 1)], M) :- !.
svector2le([(M, -1)], -M) :- !.
svector2le([(M, C)], C * M) :- !.
svector2le([(M, 1) | MCs], M + Rest) :- !, svector2le(MCs, Rest).
svector2le([(M, C) | MCs], C * M + Rest) :- svector2le(MCs, Rest).
           

inhibit_linear_expressions(svector(L), ISLE) :- !, svector2le(L, ISLE).

inhibit_linear_expressions(E1 + E2, C) :- !,
   inhibit_linear_expressions(E1, C1),
   inhibit_linear_expressions(E2, C2),
   (
      C2 = -MC2
   ->
      C = C1 - MC2
   ;
      C = C1 + C2
   ).   

inhibit_linear_expressions(T, TR) :-
   T =.. [Op | Args],
   inhibit_linear_expressions_list(Args, SArgs),
   TR =.. [Op | SArgs].

inhibit_linear_expressions_list([], []).
inhibit_linear_expressions_list([Arg | Args], [SArg | SArgs]) :-
   inhibit_linear_expressions(Arg, SArg),
   inhibit_linear_expressions_list(Args, SArgs).
   


exhibit_linear_expressions(Term, CLTerm) :-
   exhibit_le(Term, CLTerm),
   assert_le([CLTerm]).


exhibit_le(Leaf, svector([(Leaf,1)])) :- atomic(Leaf), !.
exhibit_le(+E, C) :- !, exhibit_le(E, C).

exhibit_le(-E1, C) :- !,
   exhibit_le(E1, C1),
   (
      C1 = svector(CL1)
   ->
      svector_scalar_mul(-1, CL1, CL),
      C = svector(CL)
   ;
      C = -C1
   ).

exhibit_le(E1 + E2, C) :- !,
   exhibit_le(E1, C1),
   exhibit_le(E2, C2),
   (
      (C1 = svector(CL1), C2 = svector(CL2))
   ->
      svector_sum([CL1, CL2], CL),
      C = svector(CL)
   ;
      assert_le([C1, C2]),
      C = C1 + C2
   ).

exhibit_le(E1 - E2, C) :- !, exhibit_le(E1 + (-E2), C).

exhibit_le(Term, C) :-
   Term =.. [Op | Args],
   findall(CL, (member(E, Args), exhibit_le(E, CL)), CLs),
   assert_le(CLs),
   C =.. [Op | CLs].

assert_le(L) :-
   member(svector(LE), L),
   asserta(ode_linear_expression(LE)),
   fail
   ;   
   true.

svector_scalar_mul(N, ECs, NSvector) :-
   findall((E, Coef), (member((E, C), ECs), Coef is N * C),
           NSvector).

% svector_sum(Svectors, MergedSvector) compacts Svectors according to coefficients :
% if Svectors = [[(a, 1), (b, 1)], [(a, 1), (b, -1)]], then MergedSvector = [(a, 2)]
svector_sum(Svectors, MergedSvector) :- 
   findall(X, (member(CL, Svectors), member(X, CL)), BigCL),   %appendall
   findall((Term, SumCoefs), (  bagof(Coef, member((Term, Coef), BigCL), Coefs),
                                sum_list(Coefs, SumCoefs),
                                SumCoefs \= 0 )
          , MergedSvector).

svector_plus(S1, S2, S) :-
   svector_sum([S1, S2], S).

svector_minus(S1, S2, S) :-
   svector_scalar_mul(-1, S2, MS2),
   svector_sum([S1, MS2], S).

%If Family = [A + B, B + C, D + E], will return [A, B, C, D + E]
powersplit(Family, SplitFamily) :-
   powersplit(Family, [], SplitFamily).

powersplit([], Acc, Acc).
powersplit([V | Vs], Acc, R) :-
   powersplit_el(V, Acc, AccV),
   powersplit(Vs, AccV, R).

powersplit_el([], Acc, Acc) :- !.
powersplit_el(V, [], [V]) :- !.
powersplit_el(V, [E | Es], R) :-
   intersection(V, E, VE),
   (
      VE = [(Constant, _)], (integer(Constant) ; float(Constant))
   ->
      VE_ = []
   ;
      VE_ = VE
   ), 
   svector_minus(V, VE_, V_VE),
   svector_minus(E, VE_, E_VE),
   append_nonempty([VE, E_VE], R1, R),
   powersplit_el(V_VE, Es, R1).

append_nonempty([], E, E).
append_nonempty([[]|L], E, R) :- !,
   append_nonempty(L, E, R).
append_nonempty([A | As], E, [A | R]) :- append_nonempty(As, E, R).
   
   
intersection([], _, []) :- !.
intersection(_, [], []) :- !.
intersection([A | As], [B | Bs], L) :-
   (
      A @< B
   -> 
      intersection(As, [B | Bs], L)
   ;  
      A @> B
   -> 
      intersection([A | As], Bs, L)
   ;
      L = [A | L1],
      intersection(As, Bs, L1)
   ).


add_kinetics :-
   (
      retract(ode_rate(E, X))
   -> 
      add_kinetics(E, X),
      add_kinetics
   ;  
      true
   ).

add_kinetics(E,X):-
   mark_species(E, Em),
   flatten_kinetics(Em,L),
   add_kinetics_list(L,X).

add_kinetics_list([],_).
add_kinetics_list([P|L],X):-
   product2svector(P,(1,[]),(C,R)),
   msort(R,RE),
   svector2product(RE,E),
   (
      C =\= 0
   ->
      add_ode_product(E, C, X)
   ;
      true
   ),
   add_kinetics_list(L,X).


add_ode_product(E, C, X) :-
   (
      retract(ode_product(E, D, X))
   ->
      CC is C + D,
      (
         CC =\= 0
      ->
         assertz(ode_product(E,CC,X))
      ;
         true
      )
   ;
      assertz(ode_product(E,C,X))
   ).


% transforms a product to a list L sorting out the sign and integer coefficient CR
product2svector(A*B, Svector, SvectorAB):-!,
   product2svector(B, Svector, SvectorB),
   product2svector(A, SvectorB, SvectorAB).

product2svector((A1*A2)/B, CL, CLr) :- number(A2), !, product2svector(A2 * (A1/B), CL, CLr).

product2svector((A1*A2)/B, CL, CLr) :- !, product2svector(A1 * (A2/B), CL, CLr).

product2svector(A, (C,L), (CR, L)) :- number(A), !,
   CR is C * A.

product2svector(-A, Svector, SvectorR) :- !,
   product2svector(A*(-1), Svector, SvectorR).

product2svector(A, (C,L), (C,[A|L])). % this includes the case of a conditional expression


% * parentheses to the left
svector2product([], 1).
svector2product([A|L],R):-
  svector2product(L,A,R).

svector2product([],R,R).
svector2product([B|L],A,R):-
   svector2product(L,A*B,R).


% mark_species(E, Em) checks every leaf of the term E and puts [] around species.

mark_species(E, Em) :-
   E =.. [H | L],
   (  
      L = []
   ->
      (  %E is a leaf
         (ode_species(H))
      ->
         Em = [H]
      ;
         Em = H
      )
   ;
      map_mark_species(L, Lm),
      Em =.. [H | Lm]
   ).

map_mark_species([], []).
map_mark_species([E | Es], [Em | Ems]) :-
   mark_species(E, Em),
   map_mark_species(Es, Ems).

% normalization of the kinetic expression by full decomposition
% to a sum (list) of products
flatten_kinetics(T,[T]):-
	number(T),
	!.

flatten_kinetics(+A,R):- !,
   flatten_kinetics(A,R).
flatten_kinetics(-A,R):- !,
   flatten_kinetics(A,LA),
   map_minus(LA,R).

flatten_kinetics(A+B,R):- !,
   flatten_kinetics(A,LA),
   flatten_kinetics(B,LB),
   append(LA,LB,R).
flatten_kinetics(A-B,R):- !,
   flatten_kinetics(A + (-B), R).

flatten_kinetics(A*B,R):- 
   flatten_kinetics(A,LA), !,
   flatten_kinetics(B,LB), !,
   multiply_kinetics(LA,LB,R).

flatten_kinetics(A/D,R):- !,
   flatten_kinetics(A,LA),
   map_divide(LA,D,R).

flatten_kinetics(A^B,[R^C]):-!, 
   flatten_kinetics(A,LA),
   flatten_kinetics(B,LB),
   map_sum(LA,R),
   map_sum(LB,C).

%flatten_kinetics((if _ then A else _),R):- !,
%        write_error('Error: if then else expressions are not implemented in load_ode, handling only the "then" case '(A)),
%        flatten_kinetics(A,R).

% if we get a macro, just expand it! [Sylvain]
flatten_kinetics(M, L) :-
   k_macro(M, V),
   !,
   flatten_kinetics(V, L).

flatten_kinetics(T,[T]):-
   (T=(if _ then _ else _);atom(T)), !. %ode_parameter(T);ode_macro(T)), !. % condition, parameter or macro

flatten_kinetics([T],[[T]]). %concentration

flatten_kinetics(exp(A), [exp(A)]).

flatten_kinetics(log(A), [log(A)]).

flatten_kinetics(T,_):- %FF should be completed by the other xpp arithmetic expressions
   write_error('Error: unrecognized xpp ode expression '(T)),
   fail.


map_sum([A],A).
map_sum([A|L],A+R):-
   map_sum(L,R).


map_minus(A, B) :-
   map_multiply(A, -1, B).


map_multiply([],_,[]).
map_multiply([X | L], A, [Y | R]):-
   simple_mult(X, A, Y),
   map_multiply(L,A,R).

simple_mult(1, A, A) :-
   !.

simple_mult(X, 1, X) :-
   !.

simple_mult(-X, -A, Y) :-
   !,
   simple_mult(X, A, Y).

simple_mult(-X, A, Y) :-
   !,
   simple_mult(X, -A, Y).

simple_mult(X, A, Y) :-
   (
      number(X)
   ->
      (
         number(A)
      ->
         Y is A * X
      ;
         A = A1 * A2,
         number(A1)
      ->
         YY is X * A1,
         Y = YY * A2
      ;
         A = - AA
      ->
         Z is -X,
         simple_mult(Z, AA, Y)
      ;
         Y = X * A
      )
   ;
      (
         number(A)
      ->
         (
            X = X1 * X2,
            number(X1)
         ->
            YY is A * X1,
            Y = YY * X2
         ;
            Y = A * X
         )
      ;
         A = - AA
      ->
         Y = -(X * AA)
      ;
         Y = X * A
      )
   ).


map_divide([],_,[]).
map_divide([X|L],A,[(X/A)|R]):-
   map_divide(L,A,R).

multiply_kinetics([],_,[]).
multiply_kinetics([A|L],K,R):-
   map_multiply(K,A,R1),
   multiply_kinetics(L,K,R2),
   append(R1,R2,R).

generate_biocham_rules:-
%        ode_product(E, C, X), format("Species ~w with coefficient ~w has term~n~w~n", [X, C, E]), fail ;
        repeat,
	(ode_product(E,_,_)
        ->
        format_debug(8,"merging rules with kinetics ~w~n",[E]),

        findall(S*X,(bagof(C, ode_product(E,C,X), Cs),
                     sum_list(Cs, CoefTot),
                     CoefTot<0,
                     S is -CoefTot
                    ),
                LReactant), 
        findall(S*X,(bagof(C, ode_product(E,C,X), Cs),
                     sum_list(Cs, CoefTot),
                     CoefTot>0,
                     S is CoefTot
                    ),
                LProduct), 
           
%        findall(S*X,(ode_product(E,C,X),C<0, S is -C),LReactant),
%        findall(S*X,(ode_product(E,C,X),C>0, S is  C),LProduct),


        retractall(ode_product(E,_,_)),
        reactants(LReactant,R),
        unmacro(E, UE),
        missing_modifiers(UE,R,LK0), sort(LK0, LK),
        (LK=[K] -> Mods = [] ; Mods = LK),
        append(LReactant, Mods, LReactantMods), make_solution(LReactantMods, SR),
        append(LProduct , Mods, LProductMods ), make_solution(LProductMods,  SP),
        (
           LK=[K]
        ->
           assertz(ode_rule_merge(E for SR =[K]=> SP))
        ;
           assertz(ode_rule_merge(E for SR => SP))
        ),
        fail
        ;
        !
        ).

add_biocham_rules:-
        repeat,
	(ode_rule_merge(_ for R)
        ->
        format_debug(8,"merging rules with reaction ~w~n",[R]),
        findall(F,ode_rule_merge(F for R),LF),
        retractall(ode_rule_merge(_ for R)),
        map_sum(LF,S),
        add_rule(S for R),
        fail
        ;
        !
        ).

reactants([],[]).
reactants([(_*X)|L],[X|R]):-!,
   reactants(L,R).
reactants([_|L],R):-
   reactants(L,R).

missing_modifiers(Kinetics, Reactants, Modifiers) :-
   missing_modifiers(Kinetics, Reactants, [], Modifiers).

missing_modifiers([A], L, Acc, R) :- !,
   (
      member(A,L)
   -> 
      R=Acc
   ;  
      R=[A|Acc]
   ).

missing_modifiers(Expr, L, Acc, R) :-
   Expr =.. [_ | Args],
   missing_modifiers_list(Args, L, Acc, R).

missing_modifiers_list([], _L, Acc, Acc).
missing_modifiers_list([Expr | Exprs], L) -->
   missing_modifiers(Expr, L),
   missing_modifiers_list(Exprs, L).



make_solution([],'_').
make_solution([(1*X)|L],R) :- !, make_solution([X|L], R).
make_solution([(X*1)|L],R) :- !, make_solution([X|L], R).
make_solution([(1.0*X)|L],R) :- !, make_solution([X|L], R).
make_solution([(X*1.0)|L],R) :- !, make_solution([X|L], R).
make_solution([X],X) :- !.
make_solution([X|L],S+X):-
   make_solution(L,S).
