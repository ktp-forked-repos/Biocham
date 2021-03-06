" BIOCHAM system http://contraintes.inria.fr/BIOCHAM/
" Copyright 2003-2006, INRIA, Projet Contraintes
"
" This program is free software; you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation; either version 2
" of the License, or (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with this program; if not, write to the Free Software
" Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
"
" Vim syntax file
" Language:    Biocham
" Maintainers: Sylvain Soliman <Sylvain.Soliman@inria.fr>

syn keyword Keyword  where in and parts_of not
syn keyword Keyword  for if then else
syn keyword Define   present absent undefined parameter macro
syn keyword Define   make_present_not_absent make_absent_not_present
syn keyword Define   clear_initial_state initial_state parameter
syn keyword Define   list_parameters macro list_macros

syn match   Operator    "+\|?\|-\|lt\|gt\|leq\|geq\|eq\|\*\|/\|^\|log\|exp"
syn match   Function    "\~{[^}]*}"
syn match   Delimiter   "(\|)"
syn match   Delimiter   "<\?=>\|<\?=\[[^]]*]=>"
syn match   Typedef     "\[[^]]*\]"
syn match   Typedef     "\w\+ *:"
syn match   Comment     "%.*"
syn match   String      "\(#\|@\)\w\+"
syn match   Macro       "\$\w\+"
syn match   Number      "\<\d\+\(\.\d\+\)\?\>"

syn region Typedef start="{" skip="{[^}]*}" end="}" 
syn region Function matchgroup=Keyword start="declare" end="\~"

let b:current_syntax = "biocham"

