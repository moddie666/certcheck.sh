#!/bin/bash
#
#
export LC_ALL=C
ME=$(basename $0)
USAGE="#--- CHECK CERTIFICATE VALIDITY AND FIND FITTING KEYS ---#
USAGE: $ME [.crt-file|directory|]

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

POTENTIAL BUG:
Intemediate certs, which are also checked for, are assumed to be located
in '/sslstore/intermediate' in file mode or <dir>/intermediate in directory
mode. If these do not exist the dir containing the cert file is checked."

read_multi(){
    mcount="$(grep -c "BEGIN CERTIFICATE--" $1)"
    echo -e "\e[${2}m#--- $mcount Certs in $1 ---#\e[0m"
    awk 'split_after == 1 {n++;split_after=0}; /-----END CERTIFICATE-----/{split_after=1}; {print > "/tmp/cert" n ".tmp"}' < $1
    for tempf in $(ls -A /tmp/cert*.tmp | sort -V)
    do echo -e "\t\e[${2}m----\e[0m"
       CI1=$(openssl x509 -noout -text -in $tempf | egrep 'Issuer:|Subject:|Not Before:|Not After :|Subject Alternative Name:|DNS:' | sed -r 's#^(.*)$#\\e['${2}'m\1\\e[0m#g')
       echo -e "$CI1"
       rm $tempf
    done
    veri=$(openssl verify -CAfile $1 $1 2>/dev/null || echo 'FAILED')
    echo -e "\e[${2}m---\nVerification:\e[0m $veri"
}
read_single(){
    echo -e "\e[${2}m#--- $1 ---#\e[0m"
    CI1=$(openssl x509 -noout -text -in $1 | egrep 'Issuer:|Subject:|Not Before:|Not After :|Subject Alternative Name:|DNS:' | sed -r 's#^(.*)$#\\e['${2}'m\1\\e[0m#g')
    echo -e "$CI1"
}

read_cert(){
    keysearch=0
    ccount="$(grep -c "BEGIN CERTIFICATE--" $cfile)"
    if [ "$ccount" -gt "1" ]
    then read_multi $cfile '33'
         find_key
    elif [ "$ccount" -eq "1" ]
    then read_single $cfile '32'
         find_chain
         find_key
    else echo "$cfile does not look like a cert !"
         return 1
    fi
    #read -p 'next'
    echo
}

find_chain(){
    if [ -d "$sslstore" ]
    then sslstore="/sslstore/intermediate"
    else sslstore=""
    fi
    CAFILES=$(find ${sslstore} ${wdir})
    echo "Looking for matching intermediates: ${sslstore} ${wdir} "
    for ca in $CAFILES
    do if [ "$ca" != "$cfile" ]
       then openssl verify -CAfile $ca $cfile &>/dev/null
            if [ $? -eq 0 ]
            then if [ "$(grep -c BEGIN $ca)" -gt "1" ]
                 then read_multi $ca '94'
                 else read_single $ca '96'
                 fi
            fi
       fi
    done
}

find_key(){
    echo "looking for keys in \"$wdir\""
    echo -ne "\e[91m  #--- KEY: "
    KEYS="$(grep -l "PRIVATE KEY" ${wdir}/*.{key,pem} 2>/dev/null)"
    CMOD="$(openssl x509 -noout -modulus -in $cfile)"
    for kfile in $KEYS
    do diff -s <(echo "$CMOD") <(openssl rsa -noout -modulus -in $kfile) &>/dev/null
       if [ $? -eq 0 ]
       then echo "$kfile"
            keysearch=1
       fi
    done
    if [ "$keysearch" -eq "0" ]
    then echo
    fi
    echo -en "\e[0m"
}

case $1 in 
     -h|--help) echo "$USAGE"
                exit 0;;
esac
sslstore="/sslstore/intermediate"
if [ -f "$1" ]
then FILES="$@"
elif [ -d "$1" ]
then FILES="$(find $@ -maxdepth 1 -iname '*.crt' -o -iname '*.pem' -o -iname '*.ca' -o -iname '*.intermediate')"
     sslstore="$1/intermediate"
else FILES="$(find . -maxdepth 1 -iname '*.crt' -o -iname '*.pem' -o -iname '*.ca' -o -iname '*.intermediate')"
fi

for cfile in $FILES
do if [ ! -f $cfile ]
   then echo "Not a file! [$cfile]"; continue
   fi 
   wdir="$(dirname $cfile)"
   echo -e "\e[35mChecking for: [$cfile]\e[0m"
   read_cert
done
