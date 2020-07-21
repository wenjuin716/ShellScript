#/bin/sh

INTF="enp2s5"
VLAN7_INTF="enp2s5.7"
VLAN35_INTF="enp2s5.35"
VLAN55_INTF="enp2s5.55"

muticast_setup(){
	sudo ip route add 229.200.200.0/24 dev ${INTF}
	sudo ip route add 229.7.7.0/24 dev ${VLAN7_INTF}
	sudo ip route add 229.35.35.0/24 dev ${VLAN35_INTF}
	sudo ip route add 229.55.55.0/24 dev ${VLAN55_INTF}
	sudo ip -6 route add ff08::200:0/112 dev ${INTF}
	sudo ip -6 route add ff08::7:0/112 dev ${VLAN7_INTF}
	sudo ip -6 route add ff08::35:0/112 dev ${VLAN35_INTF}
	sudo ip -6 route add ff08::55:0/112 dev ${VLAN55_INTF}
}

multicast_clear(){
	sudo ip route del 229.200.200.0/24 dev ${INTF}
	sudo ip route del 229.7.7.0/24 dev ${VLAN7_INTF}
	sudo ip route del 229.35.35.0/24 dev ${VLAN35_INTF}
	sudo ip route del 229.55.55.0/24 dev ${VLAN55_INTF}
	sudo ip -6 route del ff08::200:0/112 dev ${INTF}
	sudo ip -6 route del ff08::7:0/112 dev ${VLAN7_INTF}
	sudo ip -6 route del ff08::35:0/112 dev ${VLAN35_INTF}
	sudo ip -6 route del ff08::55:0/112 dev ${VLAN55_INTF}
}

case "$1" in
  setup)
	muticast_setup
        ;;
  clear)
	multicast_clear
        ;;
  restart)
	multicast_clear
	muticast_setup
	;;
  *)
        echo "Usage: $0 {setup|clear|restart}" >&2
        RETVAL=1
esac

