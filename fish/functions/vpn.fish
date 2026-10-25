function vpn --description "Toggle mac mini WireGuard VPN to rpi homelab"
    set -l conf wg0
    set -l action $argv[1]
    contains -- "$action" "" up down status
    or begin
        echo "usage: vpn [up|down|status]" >&2
        return 2
    end

    set -l iface (sudo wg show interfaces 2>/dev/null | string trim)

    if test "$action" = status
        if test -z "$iface"
            echo down
            return 0
        end
        echo "up ($iface)"
        sudo wg show $iface | grep -E 'peer|endpoint|latest handshake'
        # keepalive 25 renews the handshake every ~2 min, so an older one means a dead tunnel
        set -l ts (sudo wg show $iface latest-handshakes | awk 'NR==1{print $2}')
        if test -z "$ts" -o "$ts" = 0; or test (math (date +%s) - $ts) -gt 180
            echo "stale: no recent handshake"
            return 1
        end
        return 0
    end

    if test -z "$action"
        if test -n "$iface"
            set action down
        else
            set action up
        end
    end

    if test "$action" = down
        if test -z "$iface"
            echo "vpn already down"
            return 0
        end
        # a session over the tunnel dies with it, and only a LAN session can bring it back
        set -l client (string split ' ' -- "$SSH_CONNECTION")[1]
        if string match -q '10.8.0.*' -- "$client"
            echo "refusing: this SSH session runs over the VPN. Use a LAN session." >&2
            return 1
        end
        sudo wg-quick down $conf; or return
        echo "vpn down"
        return 0
    end

    if test -n "$iface"
        echo "vpn already up ($iface)"
        return 0
    end
    sudo wg-quick up $conf; or return
    set iface (sudo wg show interfaces | string trim)
    echo "vpn up ($iface) "(ifconfig $iface | awk '/inet /{print $2}')
end
