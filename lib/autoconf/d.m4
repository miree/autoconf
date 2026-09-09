# This file is part of Autoconf.                       -*- Autoconf -*-
# D language support.
# Copyright 2026 Free Software Foundation, Inc.

# This file is part of Autoconf.  This program is free
# software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Under Section 7 of GPL version 3, you are granted additional
# permissions described in the Autoconf Configure Script Exception,
# version 3.0, as published by the Free Software Foundation.
#
# You should have received a copy of the GNU General Public License
# and a copy of the Autoconf Configure Script Exception along with
# this program; see the files COPYINGv3 and COPYING.EXCEPTION
# respectively.  If not, see <https://www.gnu.org/licenses/> and
# <https://git.savannah.gnu.org/gitweb/?p=autoconf.git;a=blob_plain;f=COPYING.EXCEPTION>.

# This currently only supports GDC, the D front end included in GCC.

# ------------------- #
# Language selection.
# ------------------- #

# AC_LANG(D)
# ----------
AC_LANG_DEFINE([D], [d], [D], [GDC], [],
[ac_ext=d
ac_compile='$GDC -c $DFLAGS conftest.$ac_ext >&AS_MESSAGE_LOG_FD'
ac_link='$GDC -o conftest$ac_exeext $DFLAGS $LDFLAGS conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'
ac_compiler_gnu=yes
])

# AC_LANG_D
# ---------
AU_DEFUN([AC_LANG_D], [AC_LANG(D)])

# ------------------- #
# Producing programs.
# ------------------- #

# AC_LANG_PROGRAM(D)([PROLOGUE], [BODY])
# ---------------------------------------
# D's main() has the same shape as C's; unlike Go, D needs no enclosing
# package declaration.
m4_define([AC_LANG_PROGRAM(D)],
[$1
int
main ()
{
$2
  return 0;
}])

# _AC_LANG_IO_PROGRAM(D)
# -----------------------
# Produce source that performs I/O, necessary for proper
# cross-compiler detection.  Use core.stdc.stdio rather than
# std.stdio so this does not depend on Phobos' higher-level I/O layer.
m4_define([_AC_LANG_IO_PROGRAM(D)],
[AC_LANG_PROGRAM([import core.stdc.stdio;],
[FILE *f = fopen ("conftest.out", "w");
 if (!f)
   return 1;
 return fclose (f) != 0;
])])

# AC_LANG_CALL(D)(PROLOGUE, FUNCTION)
# ------------------------------------
# Avoid conflicting decl of main.
m4_define([AC_LANG_CALL(D)],
[AC_LANG_PROGRAM([$1
m4_if([$2], [main], ,
[extern(D) int $2();])],[$2();])])

# AC_LANG_FUNC_LINK_TRY(D)(FUNCTION)
# -----------------------------------
# Try to link a program which calls FUNCTION.  Assigning the function
# to a variable and using that, rather than calling FUNCTION directly,
# avoids the reference being optimized away.
m4_define([AC_LANG_FUNC_LINK_TRY(D)],
[AC_LANG_PROGRAM(
[extern(D) int $1();
auto f = &$1;
], [return f();])])

# AC_LANG_BOOL_COMPILE_TRY(D)(PROLOGUE, EXPRESSION)
# --------------------------------------------------
# Return a program which is valid if EXPRESSION is nonzero.
# EXPRESSION must be an integer constant expression.  A D static
# array's length must be a non-negative compile-time constant, so a
# false EXPRESSION (yielding a negative length) fails to compile.
m4_define([AC_LANG_BOOL_COMPILE_TRY(D)],
[AC_LANG_PROGRAM([$1], [int@<:@1 - 2 * !($2)@:>@ test_array;
test_array@<:@0@:>@ = 0;
return test_array@<:@0@:>@;
])])

# AC_LANG_INT_SAVE(D)(PROLOGUE, EXPRESSION)
# --------------------------------------------
m4_define([AC_LANG_INT_SAVE(D)],
[AC_LANG_PROGRAM([$1
import core.stdc.stdio;
long longval () { return $2; }
ulong ulongval () { return $2; }],
[
  FILE *f = fopen ("conftest.val", "w");
  if (!f)
    return 1;
  if (($2) < 0)
    {
      long i = longval ();
      if (i != ($2))
	return 1;
      fprintf (f, "%ld", i);
    }
  else
    {
      ulong i = ulongval ();
      if (i != ($2))
	return 1;
      fprintf (f, "%lu", i);
    }
  return ferror (f) || fclose (f) != 0;
])])

# ---------------------- #
# Looking for compilers. #
# ---------------------- #

# AC_LANG_COMPILER(D)
# --------------------
AC_DEFUN([AC_LANG_COMPILER(D)],
[AC_REQUIRE([AC_PROG_GDC])])

# AC_PROG_GDC
# -----------
AN_MAKEVAR([GDC], [AC_PROG_GDC])
AN_PROGRAM([gdc], [AC_PROG_GDC])
AC_DEFUN([AC_PROG_GDC],
[AC_LANG_PUSH([D])dnl
AC_ARG_VAR([GDC],   [D compiler command])dnl
AC_ARG_VAR([DFLAGS], [D compiler flags])dnl
_AC_ARG_VAR_LDFLAGS()dnl
# We only look for gdc, the GNU D compiler front end.
AC_CHECK_TOOLS([GDC], [m4_default([$1], [gdc])])
# Provide some information about the compiler.
_AS_ECHO_LOG([checking for _AC_LANG compiler version])
set X $ac_compile
ac_compiler=$[2]
_AC_DO_LIMIT([$ac_compiler --version >&AS_MESSAGE_LOG_FD])
m4_expand_once([_AC_COMPILER_EXEEXT])[]dnl
m4_expand_once([_AC_COMPILER_OBJEXT])[]dnl
# Default value for DFLAGS
: ${DFLAGS:="-g -O2"}
AC_LANG_POP([D])dnl
])# AC_PROG_GDC

# ------------------------------------- #
# Mixed-language linking (D with C/C++) #
# ------------------------------------- #

# _AC_D_LIBRARY_LDFLAGS
# ----------------------
#
# Determine the linker flags (e.g. "-L" and "-l") for the D runtime
# and standard libraries (druntime and Phobos, GDC's "libgphobos")
# that are required to successfully link a D object file using a C or
# C++ linker driver.  The output variable DLIBS is set to these flags.
#
# This macro is intended for the situation where a target's sources
# are predominantly C or C++, with only some D objects mixed in: such
# a target is linked with the C or C++ linker driver, since that
# driver is the one that knows how to do C++-ish things like calling
# global constructors.  But that linker driver does not know to pull
# in D's runtime libraries the way $(GDC) does when it is itself the
# link driver, so those flags have to be discovered and added to
# LDADD/LIBADD by hand.
#
# Modeled on _AC_FC_LIBRARY_LDFLAGS, which solves the analogous
# problem for Fortran, but much simplified: since only GDC (a GCC
# front end) is supported, the verbose-output flag is always "-v",
# so unlike _AC_FC_LIBRARY_LDFLAGS there is no need to probe for it,
# and none of gfortran.m4's vendor-compiler-specific output quirks
# (xlf, ifc, Portland Group, Cray, ...) apply.
AC_DEFUN([_AC_D_LIBRARY_LDFLAGS],
[AC_LANG_ASSERT([D])dnl
AC_CACHE_CHECK([for D libraries of $GDC], [ac_cv_d_libs],
[if test "x$DLIBS" != x; then
  ac_cv_d_libs="$DLIBS" # Let the user override the test.
else

AC_LANG_CONFTEST([AC_LANG_PROGRAM([])])

# Link our trivial D test program with -v to get the verbose output
# that we can then parse for D's runtime linker flags.
ac_save_DFLAGS=$DFLAGS
DFLAGS="$DFLAGS -v"
eval "set x $ac_link"
shift
_AS_ECHO_LOG([$[*]])
ac_d_v_output=`eval $ac_link AS_MESSAGE_LOG_FD>&1 2>&1 |
  sed '/^Driving:/d; /^Configured with:/d;
      '"/^[[_$as_cr_Letters]][[_$as_cr_alnum]]*=/d"`
AS_ECHO(["$ac_d_v_output"]) >&AS_MESSAGE_LOG_FD
DFLAGS=$ac_save_DFLAGS

rm -rf conftest*

ac_cv_d_libs=

# Save positional arguments (if any)
ac_save_positional="$[@]"

set X $ac_d_v_output
while test $[@%:@] != 1; do
  shift
  ac_arg=$[1]
  case $ac_arg in
	[[\\/]]*.a | ?:[[\\/]]*.a)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_d_libs, ,
	      ac_cv_d_libs="$ac_cv_d_libs $ac_arg")
	  ;;
	  # -Bstatic/-Bdynamic bracket the libraries that follow them, and
	  # GDC's own libgphobos.spec wraps -lgphobos in "-Bstatic ...
	  # -Bdynamic" (it is generally not safe to link dynamically), so
	  # these have to be kept and kept in order, not just filtered as
	  # "everything else".
	-Bstatic | -Bdynamic)
	  ac_cv_d_libs="$ac_cv_d_libs $ac_arg"
	  ;;
	  # Ignore these flags: any C or C++ linker driver already adds
	  # them by default, so repeating them in DLIBS would be redundant.
	-lang* | -lcrt*.o | -lc | -lgcc* | -[[lLR]]*=* | -link)
	  ;;
	-[[lLR]]*)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_d_libs, ,
			     ac_cv_d_libs="$ac_cv_d_libs $ac_arg")
	  ;;
	  # Ignore everything else.
  esac
done
# restore positional arguments
set X $ac_save_positional; shift

fi # test "x$DLIBS" = x
])
DLIBS="$ac_cv_d_libs"
AC_SUBST([DLIBS])
])# _AC_D_LIBRARY_LDFLAGS

# AC_D_LIBRARY_LDFLAGS
# ---------------------
AC_DEFUN([AC_D_LIBRARY_LDFLAGS],
[AC_REQUIRE([AC_PROG_GDC])dnl
AC_LANG_PUSH([D])dnl
_AC_D_LIBRARY_LDFLAGS
AC_LANG_POP([D])dnl
])# AC_D_LIBRARY_LDFLAGS
