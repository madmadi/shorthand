# Shorthand .sh :scissors:
Bash script to make shorthand or alternatives for commands and values.

# Quick installation
to install the script quickly do:
```console
$ sudo curl https://raw.githubusercontent.com/madmadi/shorthand/master/shorthand.sh -#sSLo /usr/bin/shorthand && sudo chmod 755 /usr/bin/shorthand && sudo ln -s /usr/bin/shorthand /usr/bin/sho
```
_after installation `sho` & `shorthand` commands will be available._

## Usage
for example make a name for an IP
```console
$ sho 5.254.65.166 as server-a
$ ssh $(server-a)
```
or short a command with its options
```console
$ sho ls -ltrha --color=auto as l
$ l # is same as "ls -ltrha --color=auto"
```

## See also
```console
$ sho help
```
