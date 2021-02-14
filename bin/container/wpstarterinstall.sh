#!/bin/bash
DEFAULT_VH_ROOT='/var/www/vhosts'
VH_DOC_ROOT=''
VHNAME=''
APP_NAME=''
DOMAIN=''
WWW_UID=''
WWW_GID=''
WP_CONST_CONF=''
PUB_IP=$(curl -s http://checkip.amazonaws.com)
DB_HOST='mysql'
PLUGINLIST="litespeed-cache.zip"
WP_CONT="cont"
THEME='twentytwenty'
EPACE='        '
IS_MOVE=''
DOMAIN_BASE='wpstarter.alsur.es'

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

help_message(){
	echo -e "\033[1mOPTIONS\033[0m"
    echow '-A, -app [wordpress] -D, --domain [DOMAIN_NAME]'
    echo "${EPACE}${EPACE}Example: appinstallctl.sh --app wordpress --domain example.com"
    echow '-H, --help'
    echo "${EPACE}${EPACE}Display help and exit."
    exit 0
}

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

ck_ed(){
    if [ ! -f /bin/ed ]; then
        echo "Install ed package.."
        apt-get install ed -y > /dev/null 2>&1
    fi
}

ck_unzip(){
    if [ ! -f /usr/bin/unzip ]; then
        echo "Install unzip package.."
        apt-get install unzip -y > /dev/null 2>&1
    fi
}

get_owner(){
	WWW_UID=$(stat -c "%u" ${DEFAULT_VH_ROOT})
	WWW_GID=$(stat -c "%g" ${DEFAULT_VH_ROOT})
	if [ ${WWW_UID} -eq 0 ] || [ ${WWW_GID} -eq 0 ]; then
		WWW_UID=1000
		WWW_GID=1000
		echo "Set owner to ${WWW_UID}"
	fi
}

set_vh_docroot(){
	if [ "${VHNAME}" != '' ]; then
	    VH_ROOT="${DEFAULT_VH_ROOT}/${VHNAME}"
	    VH_DOC_ROOT="${DEFAULT_VH_ROOT}/${VHNAME}/html"
		WP_CONST_CONF="${VH_DOC_ROOT}/${WP_CONT}/plugins/litespeed-cache/data/const.default.ini"
	elif [ -d ${DEFAULT_VH_ROOT}/${1}/html ]; then
	    VH_ROOT="${DEFAULT_VH_ROOT}/${1}"
        VH_DOC_ROOT="${DEFAULT_VH_ROOT}/${1}/html"
		WP_CONST_CONF="${VH_DOC_ROOT}/${WP_CONT}/plugins/litespeed-cache/data/const.default.ini"
	else
	    echo "${DEFAULT_VH_ROOT}/${1}/html does not exist, please add domain first! Abort!"
		exit 1
	fi	
}


install_wp_plugin(){
    for PLUGIN in ${PLUGINLIST}; do
        wget -q -P ${VH_DOC_ROOT}/${WP_CONT}/plugins/ https://downloads.wordpress.org/plugin/${PLUGIN}
        if [ ${?} = 0 ]; then
		    ck_unzip
            unzip -qq -o ${VH_DOC_ROOT}/${WP_CONT}/plugins/${PLUGIN} -d ${VH_DOC_ROOT}/${WP_CONT}/plugins/
        else
            echo "${PLUGINLIST} FAILED to download"
        fi
    done
    rm -f ${VH_DOC_ROOT}/${WP_CONT}/plugins/*.zip
}

app_wordpress_dl(){
	if [ ! -f "${VH_DOC_ROOT}/wp-config.php" ]; then
	  VH_DEFAULT="${DEFAULT_VH_ROOT}/${DOMAIN_BASE}"
	  if [ -n "${IS_MOVE}" ];then
	    shopt -s dotglob nullglob
	    mv ${VH_DEFAULT}/html/* ${VH_DOC_ROOT}/
	    shopt -u dotglob nullglob
	  else
	    cp -R ${VH_DEFAULT}/html/* ${VH_DOC_ROOT}/
	  fi
	else
	  if [ "${DEFAULT_VH_ROOT}/${DOMAIN_BASE}/html" = "${VH_DOC_ROOT}" ]; then
	    echo 'wordpress already exist, skip!'
	  else
	    echo 'wordpress already exist, abort!'
		  exit 1
		fi
	fi
}


change_owner(){
		if [ "${VHNAME}" != '' ]; then
		    chown -R ${WWW_UID}:${WWW_GID} ${DEFAULT_VH_ROOT}/${VHNAME} 
		else
		    chown -R ${WWW_UID}:${WWW_GID} ${DEFAULT_VH_ROOT}/${DOMAIN}
		fi
}

main(){
	set_vh_docroot ${DOMAIN}
	get_owner
	cd ${VH_DOC_ROOT}
	if [ "${APP_NAME}" = 'wpstarter' ]; then
	  app_wordpress_dl
		install_wp_plugin
		change_owner
		exit 0
	else
		echo "APP: ${APP_NAME} not support, exit!"
		exit 1	
	fi
}

check_input ${1}
while [ ! -z "${1}" ]; do
	case ${1} in
		-[hH] | -help | --help)
			help_message
			;;
		-[aA] | -app | --app) shift
			check_input "${1}"
			APP_NAME="${1}"
			;;
		-[dD] | -domain | --domain) shift
			check_input "${1}"
			DOMAIN="${1}"
			;;
		-vhname | --vhname) shift
			VHNAME="${1}"
			;;
    --domainbase) shift
      DOMAIN_BASE="${1}"
      ;;
    --move)
      IS_MOVE="--move"
      ;;
		*)
			help_message
			;;
	esac
	shift
done
main
