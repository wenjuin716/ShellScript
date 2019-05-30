#/bin/sh

INTF="enp2s5"
VLAN35_INTF="enp2s5.35"
VLAN55_INTF="enp2s5.55"

case "$1" in
  setup)
	sudo ip route add 229.200.200.0/24 dev ${INTF}
	sudo ip route add 229.35.35.0/24 dev ${VLAN35_INTF}
	sudo ip route add 229.55.55.0/24 dev ${VLAN55_INTF}
        ;;
  clear)
	sudo ip route del 229.200.200.0/24 dev ${INTF}
	sudo ip route del 229.35.35.0/24 dev ${VLAN35_INTF}
	sudo ip route del 229.55.55.0/24 dev ${VLAN55_INTF}
        ;;
  restart)
	sudo ip route del 229.200.200.0/24 dev ${INTF}
	sudo ip route del 229.35.35.0/24 dev ${VLAN35_INTF}
	sudo ip route del 229.55.55.0/24 dev ${VLAN55_INTF}
	sudo ip route add 229.200.200.0/24 dev ${INTF}
	sudo ip route add 229.35.35.0/24 dev ${VLAN35_INTF}
	sudo ip route add 229.55.55.0/24 dev ${VLAN55_INTF}
	;;
  *)
        echo "Usage: $0 {setup|clear|restart}" >&2
        RETVAL=1
esac

