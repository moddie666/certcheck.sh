```
#--- CHECK CERTIFICATE VALIDITY AND FIND FITTING KEYS ---#
USAGE: certcheck.sh [.crt-file|directory|]

This script may be used to quickly check wether an SSL certificate
is valid and what key file it is associated with.

If -h or --help is the first argument, this help will be printed.
Otherwise you may give a file, a directory name or nothing
as the first argument.

1) If given nothing, the current working dir is checked to a depth
   of 1 for certs and keys.
2) If given a directory, all certificates within will be checked and
   an attempt is made to find their keys.
3) If given a certificate name, the check will only be performed for
   this one certificate.

NOTE: Only files with the following extensions are checked
      in 'nothing' or 'directory' modes:
'*.crt' '*.pem' '*.ca' '*.intermediate' '*.key'
All in one cerificate+key combo-files should also work.
```
