#!/bin/bash
#=====/sbin/iptables admin script====
#@author renothing
#=====config=====
dir_r="rules"
#=====config end=====
#functions
Usage(){
    echo "Usage:" 1>&2
    echo "    $0 [command]" 1>&2
    echo "command:" 1>&2
cat <<EOF
	start      start all filter rules
	reload     reload all filter rules
	stop       close all filter rules
	echo       display all filter rules without apply
EOF
exit 1
}
#check uid
check_uid(){
    [[ `id -u` -ne 0 ]] && echo "please run it with root permission" && exit 1;
}
#read rules
check_ru(){
    [[ ! -d $dir_r ]] && echo " wrong rule dir" && exit 1
    [[ -z `ls $dir_r/*.txt 2> /dev/null ` ]] && echo " no rule file found in $dir_r" && exit 1
}
fw_start(){
    cat <<EOF
/sbin/iptables -t nat -F
/sbin/iptables -t nat -P PREROUTING ACCEPT
/sbin/iptables -t nat -P POSTROUTING ACCEPT
/sbin/iptables -t mangle -F
/sbin/iptables -t filter -F
#default rule
/sbin/iptables -t filter -P INPUT DROP
/sbin/iptables -t filter -P FORWARD ACCEPT
/sbin/iptables -t filter -P OUTPUT ACCEPT
#enable ssh and related
/sbin/iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
/sbin/iptables -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -t filter -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
#additional rules
EOF
    for file in `ls $dir_r/*.txt`; do
      awk -F: '
        function print_err(a,b)
    	{
    	    printf("error found in line %d of file %s \n",a,b)
    	    system("exit 1")
    	}
        {
    	if(NF==4){
	    if ( $1 !~ /^eth[0-9]+/ || $3 !~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/ || $4 !~ /^[0-9]+/ ){
    	        print_err(NR,FILENAME)
    	    }else{
    	        if($4 ~ /^[0-9]+[-,][0-9]+/){
		    sub("-",":",$4);
    	            print "/sbin/iptables -t filter -A INPUT -i",$1,"-p",$2,"-s",$3,"-m multiport --dport",$4,"-j ACCEPT"
    	        }else{
    	            print "/sbin/iptables -t filter -A INPUT -i",$1,"-p",$2,"-s",$3,"--dport",$4,"-j ACCEPT"
    	        }
    	    }
    	}else if(NF==3){
    	    if ($3 !~ /^[0-9]+/){
    		    print_err(NR,FILENAME)
    	    }else if($3 ~ /^[0-9]+$/){
		    if($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/){
    		        print "/sbin/iptables -t filter -A INPUT -p",$1,"-s",$2,"--dport",$3,"-j ACCEPT"
    		    }else{
    		        print "/sbin/iptables -t filter -A INPUT -i",$1,"-p",$2,"--dport",$3,"-j ACCEPT"
    		    }
    	    }else if($3 ~ /^[0-9]+[-,][0-9]+/){
		    sub("-",":",$3);
		    if($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/){
    		        print "/sbin/iptables -t filter -A INPUT -p",$1,"-s",$2,"-m multiport --dport",$3,"-j ACCEPT"
    		    }else{
    		        print "/sbin/iptables -t filter -A INPUT -i",$1,"-p",$2,"-m multiport --dport",$3,"-j ACCEPT"
    		    }
		}else if($3 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/){
    	        if($1 !~ /eth[0-9]+/){
    		        print_err(NR,FILENAME)
    		    }else{
    		        print "/sbin/iptables -t filter -A INPUT -i",$1,"-p",$2,"-s",$3,"-j ACCEPT"
    		    }
    	    }else{
    	        print_err(NR,FILENAME)
    	    }
    	}else if(NF==2){
    	    if ($1 ~ /eth[0-9]+/){
    		    print "/sbin/iptables -t filter -A INPUT -i",$1,"-p",$2,"-j ACCEPT"
    	    }else{
    		    if ($2 ~ /^[0-9]+$/){
    		        print "/sbin/iptables -t filter -A INPUT -p",$1,"--dport",$2,"-j ACCEPT"
    		    }else if ($2 ~ /^[0-9]+[-,][0-9]+/){
			sub("-",":",$2);
    		        print "/sbin/iptables -t filter -A INPUT -p",$1,"-m multiport --dport",$2,"-j ACCEPT"
		    }else if($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$/){
    	            print "/sbin/iptables -t filter -A INPUT -p",$1,"-s",$2,"-j ACCEPT"
    		    }else{
    		        print_err(NR,FILENAME)
    		    }
    	    }
    	}else {
    	    print_err(NR,FILENAME)
    	}
        }' $file
    done
}
#
fw_stop(){
/sbin/iptables -t nat -F
/sbin/iptables -t nat -P PREROUTING ACCEPT
/sbin/iptables -t nat -P POSTROUTING ACCEPT
/sbin/iptables -t mangle -F
/sbin/iptables -t filter -F
#default rule
/sbin/iptables -t filter -P INPUT DROP
/sbin/iptables -t filter -P FORWARD ACCEPT
/sbin/iptables -t filter -P OUTPUT ACCEPT
#enable ssh and related
/sbin/iptables -t filter -A INPUT -p tcp --dport 22 -j ACCEPT
/sbin/iptables -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -t filter -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -t filter -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

}
#get args
if  [ $# -ne 1 ];then
    Usage
fi
case $1 in
    start)      check_uid;check_ru;fw_start;;
    reload)     check_uid;fw_stop;check_ru;fw_start;;
    stop)	check_uid;fw_stop;;
    echo)	fw_start;;
    *)          Usage;;
esac
