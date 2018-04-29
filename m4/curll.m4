dnl 10/07/2016

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


dnl TEST_CURLL() function in configure.ac
dnl
dnl Substitute the linker flags -lcurl to the
dnl the variable 'CURL_LIBS' if the user enabled
dnl the various --with-* switches
AC_DEFUN([TEST_CURLL],[
  CURL_LIBS=""
  API_KEY=\""g0tm1lf"\"
  DRIVE_PORT=\""7634"\"
  WITH_WEATHER=0
  WITH_DRIVETEMP=0
  WITH_DRIVETEMP_LIGHT=0
  GMAIL_ACC=""
  GMAIL_PASS=""
  WITH_GMAIL=0
  YAHOO_ACC=""
  YAHOO_PASS=""
  WITH_YAHOO=0
  WITH_IP=0
  WITH_GITHUB=0
  GITHUB_TOKEN=""
  WITH_REDDIT=0
  REDDIT_FEED=""
  WITH_PING=0

  AC_ARG_WITH([weather],
    AS_HELP_STRING([--with-weather],
      [weather linker flag to show the todays temperature]),
    [],
    [with_weather=no]
  )

  AC_ARG_WITH([drivetemp],
    AS_HELP_STRING([--with-drivetemp],
      [Read the drive temperature from S.M.A.R.T]),
    [],
    [with_drivetemp=no]
  )

  AC_ARG_WITH([drivetemp-light],
    AS_HELP_STRING([--with-drivetemp-light],
      [Read the drive temperature from S.M.A.R.T]),
    [],
    [with_drivetemp_light=no]
  )

  AC_ARG_WITH([smartemp],
    AS_HELP_STRING([--with-smartemp],
      [Read the drive temperature from S.M.A.R.T]),
    [],
    [with_smartemp=no]
  )

  AC_ARG_WITH([gmail],
    AS_HELP_STRING([--with-gmail],
      [Count all unread emails]),
    [],
    [with_gmail=no]
  )

  AC_ARG_WITH([ip],
    AS_HELP_STRING([--with-ip],
      [Return your external ip address]),
    [],
    [with_ip=no]
  )

  AC_ARG_WITH([github],
    AS_HELP_STRING([--with-github],
      [Query GitHub and number all unread notifications]),
    [],
    [with_github=no]
  )

  AC_ARG_WITH([reddit],
    AS_HELP_STRING([--with-reddit],
      [Query reddit and number all unread notifications]),
    [],
    [with_reddit=no]
  )

  AC_ARG_WITH([pingtime],
    AS_HELP_STRING([--with-pingtime],
      [Perform a GET request and measure the round trip]),
    [],
    [with_pingtime=no]
  )

  AC_ARG_WITH([yahoo],
    AS_HELP_STRING([--with-yahoo],
      [Count all unread emails]),
    [],
    [with_yahoo=no]
  )

  AC_ARG_VAR(drive_port, [TCP port to listen to])
  AC_ARG_VAR(api_key, [weather api key])
  AC_ARG_VAR(gmail_account, [gmail account])
  AC_ARG_VAR(gmail_password, [gmail password])
  AC_ARG_VAR(github_token, [github token])
  AC_ARG_VAR(reddit_feed, [reddit feed])
  AC_ARG_VAR(yahoo_account, [yahoo account])
  AC_ARG_VAR(yahoo_password, [yahoo password])

  AS_IF([test "x$with_drivetemp" = "xyes" && test "x$with_drivetemp_light" = "xyes"],[
    with_drivetemp=no
  ])

  if [[ ! -z "${gmail_account}" ]]
  then
    GMAIL_ACC=\""${gmail_account}"\"
  fi
  if [[ ! -z "${gmail_password}" ]]
  then
    GMAIL_PASS=\""${gmail_password}"\"
  fi
  AS_IF([test "x$with_gmail" = "xyes"],[
    WITH_GMAIL=1
    AC_DEFINE_UNQUOTED([GMAIL_ACC],[$GMAIL_ACC],[gmail account])
    AC_DEFINE_UNQUOTED([GMAIL_PASS],[$GMAIL_PASS],[gmail password])
  ])

  AS_IF([test "x$with_ip" = "xyes"],[
    WITH_IP=1
  ])

  if [[ ! -z "${github_token}" ]]
  then
    GITHUB_TOKEN=\""${github_token}"\"
  fi
  AS_IF([test "x$with_github" = "xyes"],[
    WITH_GITHUB=1
    AC_DEFINE_UNQUOTED([GITHUB_TOKEN],[$GITHUB_TOKEN],[Query GitHub and number all unread notifications])
  ])

  if [[ ! -z "${reddit_feed}" ]]
  then
    REDDIT_FEED=\""${reddit_feed}"\"
  fi
  AS_IF([test "x$with_reddit" = "xyes"],[
    WITH_REDDIT=1
    AC_DEFINE_UNQUOTED([REDDIT_FEED],[$REDDIT_FEED],[Query reddit and number all unread notifications])
  ])

  AS_IF([test "x$with_pingtime" = "xyes"],[
    WITH_PING=1
  ])


  if [[ ! -z "${yahoo_account}" ]]
  then
    YAHOO_ACC=\""${yahoo_account}"\"
  fi
  if [[ ! -z "${yahoo_password}" ]]
  then
    YAHOO_PASS=\""${yahoo_password}"\"
  fi
  AS_IF([test "x$with_yahoo" = "xyes"],[
    WITH_YAHOO=1
    AC_DEFINE_UNQUOTED([YAHOO_ACC],[$YAHOO_ACC],[yahoo account])
    AC_DEFINE_UNQUOTED([YAHOO_PASS],[$YAHOO_PASS],[yahoo password])
  ])

  ifdef([LINUKS],[
    AS_IF([test "x$with_drivetemp_light" = "xyes"],[
      WITH_DRIVETEMP_LIGHT=1

      AC_CHECK_HEADERS([  \
        sys/socket.h      \
        netdb.h           \
      ],[],[
        MISSING_HEADER()
      ])

      NOTIFY([drivetemp-light])
      AC_COMPILE_IFELSE([
        AC_LANG_SOURCE([[
          #include <stdio.h>
          #include <string.h>
          #include <stdlib.h>
          #include <stdbool.h>
          #include <unistd.h>
          #include <netdb.h>
          #include <sys/socket.h>

          #define CLOSE_FD2(fd, res) \
            if (-1 == (close(fd))) { \
              freeaddrinfo(res); \
              exit(EXIT_FAILURE); \
            }

          int main(void) {
            struct addrinfo *rp = NULL, *result = NULL, hints;
            int sock = 0;
            char buf[200];
            bool got_conn = false;
            ssize_t len = 0;

            memset(&hints, 0, sizeof(hints));

            hints.ai_family = AF_INET;
            hints.ai_socktype = SOCK_STREAM;

            if (0 != (getaddrinfo("127.0.0.1", "7634", &hints, &result))) {
              return EXIT_FAILURE;
            }

            for (rp = result; NULL != rp; rp = rp->ai_next) {
              sock = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
              if (-1 == sock) {
                continue;
              }
              if (NULL == rp->ai_addr) {
                CLOSE_FD2(sock, result);
                continue;
              }
              if (0 == (connect(sock, rp->ai_addr, rp->ai_addrlen))) {
                len = recv(sock, buf, sizeof(buf), 0);
                got_conn = true;
                break;
              }
              CLOSE_FD2(sock, result);
            }

            if (true == got_conn) {
              CLOSE_FD2(sock, result);
              if (0 < len) {
                printf("%s\n", buf);
              }
            }

            if (NULL != result) {
              freeaddrinfo(result);
            }
            return EXIT_SUCCESS;
          }
        ]])
      ],[],[
        COMPILE_FAILED([drivetemp-light])
        ]
      )

    ])

    AS_IF([test "x$with_drivetemp" = "xyes"],[
      WITH_DRIVETEMP=1
    ])

    if [[ ! -z "${drive_port}" ]]
    then
      DRIVE_PORT=\""${drive_port}"\"
    fi

  ],[
  ])

  AS_IF([test "x$with_weather" = "xyes" || test "x$with_drivetemp" = "xyes" || test "x$with_gmail" = "xyes" || test "x$with_ip" = "xyes" || test "x$with_github" = "xyes" || test "x$with_reddit" = "xyes" || test "x$with_pingtime" = "xyes" || test "x$with_yahoo" = "xyes"], [
    CHECK_CFLAGZ([-O0])

    AC_CHECK_HEADERS([curl/curl.h], [
      CURL_LIBS="-lcurl"
      ],[
        ERR_MUST_INSTALL([curl and or libcurl-ssl])
    ])

    m4_foreach([LiB], [
        curl_global_init          ,
        curl_easy_init            ,
        curl_easy_setopt          ,
        curl_easy_perform         ,
        curl_easy_cleanup         ,
        curl_global_cleanup
      ],[
        AC_CHECK_LIB(curl,LiB,[],[
          MISSING_FUNC()
        ])
    ])

    if [[ ! -z "${api_key}" ]]
    then
      API_KEY=\""${api_key}"\"
    fi


    AS_IF([test "x$with_weather" = "xyes"],[
      WITH_WEATHER=1
      AC_DEFINE_UNQUOTED([API_KEY],[$API_KEY],[weather api key])
    ])

  ])

  AC_SUBST(CURL_LIBS)
  AC_DEFINE_UNQUOTED([WITH_WEATHER],[$WITH_WEATHER],[Santa is here])
  AC_DEFINE_UNQUOTED([DRIVE_PORT],[$DRIVE_PORT],[TCP port to listen to])
  AC_DEFINE_UNQUOTED([WITH_DRIVETEMP],[$WITH_DRIVETEMP],[Gettin hot in here])
  AC_DEFINE_UNQUOTED([WITH_DRIVETEMP_LIGHT],[$WITH_DRIVETEMP_LIGHT],[Gettin hot in here])
  AC_DEFINE_UNQUOTED([WITH_GMAIL],[$WITH_GMAIL],[Count all unread emails])
  AC_DEFINE_UNQUOTED([WITH_IP],[$WITH_IP],[Return your external ip address])
  AC_DEFINE_UNQUOTED([WITH_GITHUB],[$WITH_GITHUB],[Query GitHub and number all unread notifications])
  AC_DEFINE_UNQUOTED([WITH_REDDIT],[$WITH_REDDIT],[Query reddit and number all unread notifications])
  AC_DEFINE_UNQUOTED([WITH_PING],[$WITH_PING],[Perform a GET request and measure the round trip])
  AC_DEFINE_UNQUOTED([WITH_YAHOO],[$WITH_YAHOO],[Count all unread emails])

  AS_IF([test "x$with_weather" = "xyes" || test "x$with_drivetemp" = "xyes" || test "x$with_gmail" = "xyes" || test "x$with_ip" = "xyes" || test "x$with_github" = "xyes" || test "x$with_reddit" = "xyes" || test "x$with_pingtime" = "xyes" || test "x$with_yahoo" = "xyes"], [
    AC_LINK_IFELSE([
      AC_LANG_SOURCE([[
        #include <stdio.h>
        #include <curl/curl.h>
        int main(void) {
          CURL *curl = NULL;
          CURLcode res;
          curl_global_init(CURL_GLOBAL_ALL);
          if (NULL == (curl = curl_easy_init())) {
            goto error;
          }
          curl_easy_setopt(curl, CURLOPT_URL, "http://google.com");
          curl_easy_setopt(curl, CURLOPT_ACCEPT_ENCODING, "gzip");
          res = curl_easy_perform(curl);
          if (CURLE_OK != res) {
            goto error;
          }
        error:
          if (NULL != curl) {
            curl_easy_cleanup(curl);
          }
          curl_global_cleanup();
          return 0;
        }
      ]])
    ],[],[
        LINK_FAILED([curl])
      ]
    )
  ])

])
