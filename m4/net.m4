dnl Copyright 08/10/2015
dnl Aaron Caffrey https://github.com/wifiextender

dnl This program is free software; you can redistribute it and/or modify
dnl it under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 2 of the License, or
dnl (at your option) any later version.

dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
dnl GNU General Public License for more details.

dnl You should have received a copy of the GNU General Public License
dnl along with this program; if not, write to the Free Software
dnl Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
dnl MA 02110-1301, USA.


dnl TEST_NET() function in configure.ac
dnl
dnl Allow the user to compile the program
dnl without net related functions, thus
dnl decreasing the required dependencies.
dnl
dnl Did not included tests for some of the Net
dnl headers as they fail to compile just by including
dnl them in gcc, but pass the tests in clang. Is there
dnl are any _POSIX_SOURCE m4 alternative to compile a
dnl test case on the fly ?
dnl
dnl --with-pci will check for the presence of pci headers and
dnl substitue the linker flags -lpci to the variable PCI_LIBS
dnl as well to mitigate the GCC -O2 bug.
dnl
dnl --with-net will check for the presence of iproute2 headers
dnl used in the net functions and substitute appropriate macro
dnl so the program to be compiled with/out net functions support.
AC_DEFUN([TEST_NET],[
  WITH_NET=1
  WITH_PCI=1
  PCI_LIBS=""

  AC_ARG_WITH([net],
    AS_HELP_STRING([--with-net],
      [Net funcs]),
    [],
    [with_net=yes]
  )

  AS_IF([test "x$with_net" = "xno"], [
    WITH_NET=0
  ])

  AS_IF([test "x$with_net" = "xyes"], [

    AC_CHECK_HEADERS([    \
      linux/if_link.h     \
      ifaddrs.h           \
      arpa/inet.h         \
      netpacket/packet.h  \
      sys/socket.h        \
      net/if.h            \
      sys/ioctl.h         \
      linux/sockios.h     \
      linux/ethtool.h     \
      netdb.h             \
    ],[],[
      ERR([Missing core header files.])
    ])

    AC_CHECK_FUNCS([ \
      getifaddrs     \
      freeifaddrs    \
      getaddrinfo    \
      freeaddrinfo   \
      socket         \
      ioctl          \
      inet_ntop      \
    ],[],[
      ERR([Missing core library functions.])
    ])

    NOTIFY([getifaddrs])
    AC_COMPILE_IFELSE([
      AC_LANG_SOURCE([[
        #include <ifaddrs.h>
        int main(void) {
          struct ifaddrs *ifaddr;
          if (-1 == getifaddrs(&ifaddr)) {
            return 0;
          }
          freeifaddrs(ifaddr);
          return 0;
        }
      ]])
    ],[],[
      COMPILE_FAILED([getifaddrs])
      ]
    )

  ])

  AC_ARG_WITH([pci],
    AS_HELP_STRING([--with-pci],
      [PCI funcs]),
    [],
    [with_pci=yes]
  )

  AS_IF([test "x$with_pci" = "xno"], [
    WITH_PCI=0
    CHECK_CFLAGZ([-O2])
  ])

  AS_IF([test "x$with_pci" = "xyes"], [
    PCI_LIBS="-lpci"

    dnl For very first time I stumble upon GCC -O2 bug.
    dnl It hangs on pci_init with -O2
    CHECK_CFLAGZ([-O0])

    AC_CHECK_HEADERS([ \
      pci/pci.h        \
    ],[],[
      ERR([Missing core header files.])
    ])

  ])

  AC_SUBST(PCI_LIBS)
  AC_DEFINE_UNQUOTED([WITH_NET],[$WITH_NET],[Net funcs])
  AC_DEFINE_UNQUOTED([WITH_PCI],[$WITH_PCI],[PCI funcs])

])
