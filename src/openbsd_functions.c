/*
   09/08/2016

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

#include "config.h" /* Auto-generated */

#include <sys/stat.h>
#include <sys/time.h>
#include <sys/param.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/sensors.h>
#include <machine/apmvar.h>

#include "include/headers.h"
#include "include/openbzd.h"

/*
 Used resources:
  $OpenBSD: uvm_meter.c,v 1.36 2015/03/14 03:38:53 jsg Exp $
  $OpenBSD: machine.c,v 1.63 2007/11/01 19:19:48 otto Exp $
*/

void
get_ram(char *str1, uint8_t num) {
  uintmax_t total = 0, freeram = 0, pz = 0;

  pz      = (uintmax_t)sysconf(_SC_PAGESIZE);
  total   = ((uintmax_t)sysconf(_SC_PHYS_PAGES) * pz) / MB;
  freeram = ((uintmax_t)sysconf(_SC_AVPHYS_PAGES) * pz) / MB;

  switch(num) {
    case 1:
    case 2:
      FILL_ARR(str1, FMT_UINT "%s",
        ((1 == num) ? total: freeram), "MB");
      break;
    case 3:
      FILL_ARR(str1, FMT_UINT "%s", (total - freeram), "MB");
      break;
    case 5:
      FILL_UINT_ARR(str1, ((total - freeram) * 100) / total);
      break;
  }
}


void
match_feature(char *str1, uint8_t sens_type, uint8_t sens_num) {
  int mib[] = { CTL_HW, HW_SENSORS, 0, sens_type, 0 };
  struct sensordev dev;
  struct sensor sens;
  uint_fast16_t rpm[MAX_FANS+1];
  uint8_t x = 0, y = 0, z = 0;
  uintmax_t temp = 0;
  char buffer[VLA];
  char *all = buffer;
  bool found_fans = false;

  memset(rpm, 0, sizeof(rpm));
  memset(&dev, 0, sizeof(struct sensordev));
  memset(&sens, 0, sizeof(struct sensor));

  size_t dev_len = sizeof(dev), sens_len = sizeof(sens);
  SYSCTLVAL(mib, 3, &dev, &dev_len);

  for (mib[4] = 0; mib[4] < dev.maxnumt[sens_type]; mib[4]++) {
    if (0 != (sysctl(mib, 5, &sens, &sens_len, NULL, 0))) {
      break;
    }
    if (0 != sens_len &&
        !(sens.flags & (SENSOR_FINVALID | SENSOR_FUNKNOWN))) {

      switch(sens_type) {
        case SENSOR_VOLTS_DC:
          GLUE2(all, "%.2f ", ((float)sens.value / 1000000.0));
          break;

        case SENSOR_TEMP:
          {
            if (x == sens_num) {
              temp = (uintmax_t)sens.value;
            }
            x++;
          }
          break;

        case SENSOR_FANRPM:
          {
            if (MAX_FANS != z) {
              rpm[z++] = (uint_fast16_t)sens.value;
            }
            found_fans = true;
          }
          break;
      }
    }
  }

  if (SENSOR_VOLTS_DC == sens_type && '\0' != buffer[0]) {
    size_t len = strlen(buffer);
    buffer[len-1] = '\0';

    FILL_STR_ARR(1, str1, buffer);
    return;
  }
  if (SENSOR_TEMP == sens_type) {
    if (999999999 < temp) { /* > 99C */
      FILL_UINT_ARR(str1, temp / 100000000);
    } else {
      FILL_UINT_ARR(str1, ((99999999 < temp) ?
        temp / 10000000 : temp / 1000000)); /* > 9C || < 9C */
    }
    return;
  }
  if (found_fans) {
    check_fan_vals(str1, rpm, z);
  }
}


void
get_voltage(char *str1) {
  match_feature(str1, SENSOR_VOLTS_DC, 0);
}


void
get_mobo_temp(char *str1) {
  match_feature(str1, SENSOR_TEMP, 1);
}


void
get_fans(char *str1) {
  match_feature(str1, SENSOR_FANRPM, 0);
}


void
get_cpu_temp(char *str1) {
  match_feature(str1, SENSOR_TEMP, 0);
}


void
get_mobo(char *str1) {
  int mib[] = { CTL_HW, HW_VENDOR };
  int mib2[] = { CTL_HW, HW_PRODUCT };
  char vendor[100], model[100];
  size_t len = sizeof(vendor);

  SYSCTLVAL(mib, 2, &vendor, &len);
  SYSCTLVAL(mib2, 2, &model, &len);

  split_n_index(vendor);
  split_n_index(model);

  FILL_STR_ARR(2, str1, vendor, model);
}


/*
 * Entirely based on:
 *  $OpenBSD: apmd.c,v 1.49 2007/11/24 14:58:44 deraadt Exp $
 * The source mentioned different values when
 * using Crapple machine that is charging the battery
*/
void
get_battery(char *str1) {
  struct apm_power_info bstate;
  uintmax_t percent = 0;
  int fd = 0;

  FILL_STR_ARR(1, str1, "Null");
  memset(&bstate, 0, sizeof(struct apm_power_info));

  if (0 != (fd = open("/dev/apm", O_RDONLY))) {
    return;
  }
  if (0 != (ioctl(fd, APM_IOC_GETPOWER, &bstate))) {
    close(fd);
    return;
  }

  percent = bstate.battery_life;
  close(fd);

  FILL_UINT_ARR(str1, percent);
}