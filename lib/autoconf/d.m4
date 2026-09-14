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

# This supports GDC (the D front end included in GCC), LDC (the LLVM
# D compiler, "ldc2"), and DMD (the reference compiler).  GDC speaks
# GCC's command-line and "-v" dialect throughout; DMD and LDC instead
# share a dialect of their own (DMD's), which differs from GDC's in
# ways that matter to the macros below -- see _AC_D_COMPILER_VENDOR
# and _AC_D_LIBRARY_LDFLAGS.

# ------------------- #
# Language selection.
# ------------------- #

# AC_LANG(D)
# ----------
# ac_compile needs no vendor override: all three compilers default to
# naming a compiled object after its source (conftest.$OBJEXT for
# conftest.$ac_ext), so no explicit output flag is ever needed there.
# ac_link does need one -- see _AC_D_LINK_VARS, which this calls.
# $ac_cv_d_compiler_vendor is not yet known the first time AC_LANG(D)
# runs (AC_PROG_DC pushes the D language before it has identified
# $DC), so _AC_D_LINK_VARS's default there is the GDC-flavored,
# space-separated "-o"; AC_PROG_DC calls it again once the vendor is
# known, and so does every subsequent AC_LANG_PUSH([D]) (e.g. from
# AC_D_LIBRARY_LDFLAGS), since AC_LANG_PUSH re-runs this block and
# would otherwise clobber the override back to the GDC-flavored
# default on every push.
AC_LANG_DEFINE([D], [d], [D], [DC], [],
[ac_ext=d
ac_compile='$DC -c $DFLAGS conftest.$ac_ext >&AS_MESSAGE_LOG_FD'
_AC_D_LINK_VARS
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
# package declaration.  Portable across GDC, DMD, and LDC.
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
[AC_REQUIRE([AC_PROG_DC])])

# _AC_D_LINK_VARS
# ----------------
# Set ac_link (and ac_compiler_gnu, and DFLAGS's default) from
# $ac_cv_d_compiler_vendor, which is empty the first time AC_LANG(D)
# runs (before AC_PROG_DC has identified $DC) and so falls through to
# the GDC-flavored default below -- fine, since that is only used
# transiently until _AC_D_COMPILER_VENDOR determines the real vendor
# and calls this again.  Called both from AC_LANG(D) and from
# _AC_D_COMPILER_VENDOR, since AC_LANG_PUSH([D]) re-runs AC_LANG(D)'s
# block on every push (e.g. from AC_D_LIBRARY_LDFLAGS, long after
# AC_PROG_DC returned) and would otherwise clobber the override back
# to the GDC-flavored default each time.
AC_DEFUN([_AC_D_LINK_VARS],
[AS_CASE([$ac_cv_d_compiler_vendor],
 [ldc | dmd],
   [ac_compiler_gnu=no
    ac_link='$DC -of=conftest$ac_exeext $DFLAGS $LDFLAGS conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'],
 [ac_compiler_gnu=yes
  ac_link='$DC -o conftest$ac_exeext $DFLAGS $LDFLAGS conftest.$ac_ext $LIBS >&AS_MESSAGE_LOG_FD'])
])# _AC_D_LINK_VARS

# _AC_D_COMPILER_VENDOR
# ----------------------
# GDC accepts a space-separated "-o file" and bare "-lfoo"/"-Lpath"
# linker flags, and understands the leveled "-O2".  DMD and LDC share
# a different dialect: the output name must be glued directly onto
# "-of" (a space-separated "-of file" is a hard *error* on both), any
# flag meant for the underlying linker must be individually wrapped
# as "-L<flag>" (bare "-lfoo" is rejected outright), and dmd's
# optimizer flag is the level-less "-O" rather than "-O2" (ldc2 does
# accept "-O2").  Probe $DC's "--version" banner once to tell which
# dialect is in play, then call _AC_D_LINK_VARS to apply it.  This is
# the same kind of vendor probing _AC_FC_LIBRARY_LDFLAGS's callers do
# for Fortran, simplified to the three known D vendors.
#
# Only ac_link needs overriding for DMD/LDC's own dialect, not
# ac_compile: all three compilers default to naming a compiled object
# after its source, so the plain "-c $DFLAGS conftest.$ac_ext" from
# AC_LANG(D) already works unchanged.  But an Automake-generated
# Makefile's own per-object compile rules are not so accommodating:
# they hardcode a space-separated "-o $@" (depend2.am's shared
# template, used by every language), which is a hard error on DMD and
# LDC, and any "-l"/"-L"/"-Wl," a package's own $LDFLAGS/$LIBS or
# $DFLAGS might carry (e.g. from AC_CHECK_LIB or pkg-config) hits the
# same rejection.  Route $DC itself through Automake's 'compile'
# script for these two vendors, exactly as _AM_PROG_CC_C_O routes $CC
# through it for compilers that reject "-c -o" together (e.g. MSVC):
# 'compile' already knows how to translate D's dialect, via the
# 'func_d_wrapper' case added alongside its existing 'func_cl_wrapper'
# for cl.exe.  This also transparently fixes the "-l"/"-L"/"-Wl,"
# problem for $DC's own uses within this configure run (this macro's
# ac_link included), since 'compile' translates those wherever they
# appear, not just in the "-o" position.
#
# Unlike _AM_PROG_CC_C_O, this cannot unconditionally
# AC_REQUIRE_AUX_FILE([compile]): that would statically demand the
# file for *any* use of AC_PROG_DC, including a bare-Autoconf package
# (no Automake) that never needs the wrapper at all, since
# AC_REQUIRE_AUX_FILE's requirement is recorded at macro-expansion
# time, before it is known at configure runtime whether $DC even turns
# out to be LDC or DMD.  Instead, check for the file at runtime and
# warn (rather than error) if it is missing: an Automake-based package
# almost always has it already, since AM_PROG_CC_C_O (run as part of
# ordinary AC_PROG_CC) requires it unconditionally for exactly the
# analogous C-compiler problem; a pure-D Automake package that never
# calls AC_PROG_CC should add its own AC_REQUIRE_AUX_FILE([compile]).
AC_DEFUN([_AC_D_COMPILER_VENDOR],
[AC_CACHE_CHECK([for the vendor of $DC], [ac_cv_d_compiler_vendor],
[ac_cv_d_compiler_vendor=gnu
AS_IF([test -n "$DC"],
[AS_CASE([`$DC --version 2>&1`],
  [*'LDC '*],             [ac_cv_d_compiler_vendor=ldc],
  [*'DMD'* | *' D Compiler'*], [ac_cv_d_compiler_vendor=dmd])])])
AS_CASE([$ac_cv_d_compiler_vendor],
  [ldc | dmd],
    [AS_IF([test -f "${ac_aux_dir}compile"],
       [DC="${ac_aux_dir}compile $DC"],
       [AC_MSG_WARN([Automake's 'compile' script was not found in the auxiliary directory; $DC's dialect differences from GDC (the "-o FILE" and "-l"/"-L" conventions) will not be translated, and Automake-generated build rules for D sources may fail to compile or link.  A package that also checks for a C compiler already gets this script installed automatically; a pure-D package should arrange for it explicitly.])])])
_AC_D_LINK_VARS
AS_IF([test "x$ac_cv_d_compiler_vendor" = xdmd],
  [: ${DFLAGS:="-g -O"}],
  [: ${DFLAGS:="-g -O2"}])
])# _AC_D_COMPILER_VENDOR

# AC_PROG_DC
# -----------
# Find a D compiler to use: GDC, LDC ("ldc2"), or DMD, in that order
# (GDC first, since it needs nothing beyond a working GCC install).
AN_MAKEVAR([DC], [AC_PROG_DC])
AN_PROGRAM([gdc], [AC_PROG_DC])
AN_PROGRAM([ldc2], [AC_PROG_DC])
AN_PROGRAM([dmd], [AC_PROG_DC])
AC_DEFUN([AC_PROG_DC],
[AC_LANG_PUSH([D])dnl
AC_ARG_VAR([DC],   [D compiler command])dnl
AC_ARG_VAR([DFLAGS], [D compiler flags])dnl
_AC_ARG_VAR_LDFLAGS()dnl
AC_CHECK_TOOLS([DC], [m4_default([$1], [gdc ldc2 dmd])])
_AC_D_COMPILER_VENDOR
# Provide some information about the compiler.
_AS_ECHO_LOG([checking for _AC_LANG compiler version])
set X $ac_compile
ac_compiler=$[2]
_AC_DO_LIMIT([$ac_compiler --version >&AS_MESSAGE_LOG_FD])
m4_expand_once([_AC_COMPILER_EXEEXT])[]dnl
m4_expand_once([_AC_COMPILER_OBJEXT])[]dnl
AC_LANG_POP([D])dnl
])# AC_PROG_DC

# AC_PROG_GDC
# -----------
# Legacy, GDC-only entry point, kept for packages that specifically
# want GDC (e.g. to rely on ImportC or other GDC-specific behavior)
# rather than whichever of GDC/LDC/DMD happens to be installed.
# Equivalent to 'AC_PROG_DC([gdc])' with GDC's traditional variable
# name doubling as an alias for DC.
AC_DEFUN([AC_PROG_GDC],
[AC_PROG_DC([m4_default([$1], [gdc])])
GDC=$DC
AC_SUBST([GDC])
])# AC_PROG_GDC

# ------------------------------------- #
# Mixed-language linking (D with C/C++) #
# ------------------------------------- #

# _AC_D_LIBRARY_LDFLAGS
# ----------------------
#
# Determine the linker flags (e.g. "-L" and "-l") for the D runtime
# and standard libraries (druntime and Phobos -- GDC's "libgphobos",
# DMD's "libphobos2", LDC's "libphobos2-ldc"/"libdruntime-ldc") that
# are required to successfully link a D object file using a C or C++
# linker driver.  The output variable DLIBS is set to these flags.
#
# This macro is intended for the situation where a target's sources
# are predominantly C or C++, with only some D objects mixed in: such
# a target is linked with the C or C++ linker driver, since that
# driver is the one that knows how to do C++-ish things like calling
# global constructors.  But that linker driver does not know to pull
# in D's runtime libraries the way $(DC) does when it is itself the
# link driver, so those flags have to be discovered and added to
# LDADD/LIBADD by hand.
#
# Modeled on _AC_FC_LIBRARY_LDFLAGS, which solves the analogous
# problem for Fortran, but simplified to the three known D vendors,
# which fall into two families for the purpose of this macro:
#
# - GDC's "-v" output is GCC's familiar multi-line trace, ending in
#   the real collect2/linker invocation among lines of build noise
#   ("Driving:", "Configured with:", environment dumps) -- handled by
#   the pre-existing 'gnu' case below, unchanged.
#
# - DMD's and LDC's "-v" output is a build log of internal compiler
#   passes (parse, semantic, codegen, ...) ending in a single line
#   that hands off to a C linker driver, e.g.
#     cc conftest.o -o conftest -Xlinker --export-dynamic -L/usr/lib \
#       -Xlinker -Bstatic -lphobos2 -Xlinker -Bdynamic -lpthread ...
#   Since DMD/LDC only understand the "-L<flag>" convention
#   themselves, every flag meant for the linker arrives wrapped as
#   either "-Xlinker FLAG" or "-Wl,FLAG,FLAG,...": the 'ldc | dmd'
#   case below takes that last line, unwraps both forms into a flat
#   list of plain flags, and classifies them exactly as the 'gnu'
#   case does.
AC_DEFUN([_AC_D_LIBRARY_LDFLAGS],
[AC_LANG_ASSERT([D])dnl
AC_CACHE_CHECK([for D libraries of $DC], [ac_cv_d_libs],
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
ac_d_v_output=`eval $ac_link AS_MESSAGE_LOG_FD>&1 2>&1`
AS_ECHO(["$ac_d_v_output"]) >&AS_MESSAGE_LOG_FD
DFLAGS=$ac_save_DFLAGS

rm -rf conftest*

ac_cv_d_libs=

# Save positional arguments (if any)
ac_save_positional="$[@]"

AS_CASE([$ac_cv_d_compiler_vendor],
[ldc | dmd],
[# Take the last non-empty line: the actual link invocation.
ac_d_link_line=`AS_ECHO(["$ac_d_v_output"]) | sed -n '/./{H;$!d};${x;s/.*\n//;p}'`

# Pass 1: unwrap "-Xlinker FLAG" and "-Wl,FLAG,..." into a flat list
# of plain flags, alongside everything already unwrapped.
set X $ac_d_link_line
shift
ac_d_flat=
while test $[@%:@] != 0; do
  ac_arg=$[1]
  shift
  case $ac_arg in
    -Xlinker)
      ac_d_flat="$ac_d_flat $[1]"
      shift
      ;;
    -Wl,*)
      ac_wl_arg=`AS_ECHO(["$ac_arg"]) | sed 's/^-Wl,//'`
      ac_save_ifs=$IFS; IFS=,
      for ac_wl_flag in $ac_wl_arg; do
	IFS=$ac_save_ifs
	ac_d_flat="$ac_d_flat $ac_wl_flag"
	IFS=,
      done
      IFS=$ac_save_ifs
      ;;
    *)
      ac_d_flat="$ac_d_flat $ac_arg"
      ;;
  esac
done

# Pass 2: classify exactly as the 'gnu' case below does.
set X $ac_d_flat
while test $[@%:@] != 1; do
  shift
  ac_arg=$[1]
  case $ac_arg in
	[[\\/]]*.a | ?:[[\\/]]*.a)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_d_libs, ,
	      ac_cv_d_libs="$ac_cv_d_libs $ac_arg")
	  ;;
	-Bstatic | -Bdynamic)
	  ac_cv_d_libs="$ac_cv_d_libs $ac_arg"
	  ;;
	-lang* | -lcrt*.o | -lc | -lgcc* | -[[lLR]]*=* | -link)
	  ;;
	-[[lLR]]*)
	  _AC_LIST_MEMBER_IF($ac_arg, $ac_cv_d_libs, ,
			     ac_cv_d_libs="$ac_cv_d_libs $ac_arg")
	  ;;
	  # Ignore everything else, including the linker driver's own
	  # name, the object file, and the "-o exe" pair.
  esac
done
],
[# gnu (GDC): GCC's familiar multi-line "-v" trace.
ac_d_v_output=`AS_ECHO(["$ac_d_v_output"]) |
  sed '/^Driving:/d; /^Configured with:/d;
      '"/^[[_$as_cr_Letters]][[_$as_cr_alnum]]*=/d"`

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
])

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
[AC_REQUIRE([AC_PROG_DC])dnl
AC_LANG_PUSH([D])dnl
_AC_D_LIBRARY_LDFLAGS
AC_LANG_POP([D])dnl
])# AC_D_LIBRARY_LDFLAGS
