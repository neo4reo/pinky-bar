/*
   Copyright 07/06/2015, 07/18/2016
   Aaron Caffrey https://github.com/wifiextender

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
*/

/* The pragma directives are here
 * to mute the gcc twisted vision,
 * and clangs inabillity to distinguish
 * C from C++
 *
 * https://llvm.org/bugs/show_bug.cgi?id=21689 
 * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=66425
 * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=25509
 *
 * Do not add any -Wno flags just to mute the compilers snafus
 * */

#include <sys/sysinfo.h>

#include "config.h" /* Auto-generated */
#include "include/headers.h"

void 
get_ram(char *str1, unsigned char num) {
  uintmax_t used = 0, total = 0;
  struct sysinfo mem;

  if (-1 == (sysinfo(&mem))) {
    FUNC_FAILED("sysinfo()");
  }

  switch(num) {
    case 1:
      FILL_ARR(str1, FMT_UINT "%s",
        (uintmax_t)mem.totalram / MB, "MB");
      break;
    case 2:
      FILL_ARR(str1, FMT_UINT "%s",
        (uintmax_t)mem.freeram / MB, "MB");
      break;
    case 3:
      FILL_ARR(str1, FMT_UINT "%s",
        (uintmax_t)mem.sharedram / MB, "MB");
      break;
    case 4:
      FILL_ARR(str1, FMT_UINT "%s",
        (uintmax_t)mem.bufferram / MB, "MB");
      break;
    case 5:
      {
        total   = (uintmax_t) mem.totalram / MB;
        used    = (uintmax_t) (mem.totalram - mem.freeram -
                         mem.bufferram - mem.sharedram) / MB;
        FILL_UINT_ARR(str1, (used * 100) / total);
      }
      break;
  }

}


void
get_ssd_model(char *str1, char *str2) {
  FILE *fp;
  char model[VLA];
  FILL_ARR(model, "%s%s%s", "/sys/block/", str2, "/device/model");

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
  OPEN_X(fp, model, "%[^\n]", model);
#pragma GCC diagnostic pop

  FILL_STR_ARR(1, str1, model);

}


void
get_loadavg(char *str1) {
  struct sysinfo up;
  if (-1 == (sysinfo(&up))) {
    FUNC_FAILED("sysinfo()");
  }
  FILL_ARR(str1, "%.2f %.2f %.2f",
    (float)up.loads[0] / 65535.0,
    (float)up.loads[1] / 65535.0,
    (float)up.loads[2] / 65535.0);
}


void 
get_voltage(char *str1) {
  float voltage[4];
  FILE *fp;
  uint_fast16_t x = 0;

  const char *voltage_files[] = {
    VOLTAGE_FILE("0"),
    VOLTAGE_FILE("1"),
    VOLTAGE_FILE("2"),
    VOLTAGE_FILE("3")
  };

  for (x = 0; x < 4; x++) {
    if (NULL == (fp = fopen(voltage_files[x], "r"))) {
      exit_with_err(CANNOT_OPEN, voltage_files[x]);
    }
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
    fscanf(fp, "%f", &voltage[x]);
#pragma GCC diagnostic pop
    fclose(fp);

    voltage[x] /= (float)1000.0;
  }
  FILL_ARR(str1, "%.2f %.2f %.2f %.2f",
    voltage[0], voltage[1], voltage[2], voltage[3]);
}


void 
get_mobo(char *str1) {
  FILE *fp;
  char vendor[VLA], name[VLA];

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
  OPEN_X(fp, MOBO_VENDOR, "%s", vendor);
#pragma GCC diagnostic pop

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
  OPEN_X(fp, MOBO_NAME, "%s", name);
#pragma GCC diagnostic pop

  FILL_STR_ARR(2, str1, vendor, name);
}


void
get_mobo_temp(char *str1) {
  get_temp(MOBO_TEMP_FILE, str1);
}


void 
get_statio(char *str1, char *str2) {
  uintmax_t statio[7];
  char stat_file[VLA];
  FILL_ARR(stat_file, "%s%s%s", "/sys/block/", str2, "/stat");

  memset(statio, 0, sizeof(statio));

  FILE *fp = fopen(stat_file, "r");
  if (NULL == fp) {
    exit_with_err(CANNOT_OPEN, stat_file);
  }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
  if (fscanf(fp, FMT_UINT FMT_UINT FMT_UINT FMT_UINT FMT_UINT FMT_UINT FMT_UINT,
    &statio[0], &statio[1], &statio[2], &statio[3],
    &statio[4], &statio[5], &statio[6]) == EOF) {
      fclose(fp);
      exit_with_err(ERR, "reading the stat file failed");
  }
#pragma GCC diagnostic pop
  fclose(fp);

  FILL_ARR(str1, "Read " FMT_UINT " MB, Written " FMT_UINT " MB",
    BYTES_TO_MB(statio[2]), BYTES_TO_MB(statio[6]));
}


/* Thanks to https://bugzilla.kernel.org/show_bug.cgi?id=83411 */
void
get_battery(char *str1) {
  uintmax_t used = 0, total = 0, percent = 0, num = 0;
  char temp[VLA];
  BATTERY_TOTAL(temp, num);

  FILE *fp = fopen(temp, "r");
  if (NULL == fp) {
    num = 1;
    BATTERY_TOTAL(temp, num);

    if (NULL == (fp = fopen(temp, "r"))) {
      exit_with_err(CANNOT_OPEN, "BAT0 and BAT1");
    }
  }

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
  fscanf(fp, FMT_UINT, &total);
#pragma GCC diagnostic pop
  fclose(fp);

  BATTERY_USED(temp, num);

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
  OPEN_X(fp, temp, FMT_UINT, &used);
#pragma GCC diagnostic pop

  percent = (used * 100) / total;
  FILL_UINT_ARR(str1, percent);
}
