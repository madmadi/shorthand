# Shorthand .sh :scissors:
Bash script to make shorthand or alternatives for commands and values.

# Quick installation
`$ sudo curl https://raw.githubusercontent.com/madmadi/shorthand/master/shorthand.sh -#sSLo /usr/bin/shorthand && sudo chmod 755 /usr/bin/shorthand && sudo ln -s /usr/bin/shorthand /usr/bin/sho`
_after installation `sho` & `shorthand` will be available._

## Usage
`$ sho 5.254.65.166 as server-a` and then you can do `$ ssh $(server-a)`
`$ sho ls -ltrha --color=auto as l` then `$ l` is same as `$ ls -ltrha --color=auto`

See also `$ sho help`
