# gl_functions.sh

## Guideloom Bash functions

This is a small "library" of bash functions that are used by other scripts. All functions begin with "gl_" to identify them as coming from this library. To include them in your script, add the following lines to your bash scripts.
```
#!/bin/bash
# load GL functions
glfunc_path=/home/vbox/bin/gl_functions.sh

if [[ ! -f ${glfunc_path} ]]; then
  echo "Error: Cannot find GL functions script."
  echo "       Check path ${glfunc_path}."
  echo "       Exiting."
  exit 1
fi

# load up the functions
. ${glfunc_path}
```

---
   Copyright (C) 2019  GuideLoom Inc./Trevor Paquette

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.
