function vpn --description "Toggle mac mini WireGuard VPN to rpi homelab"
    set -l iface (sudo wg show interfaces 2>/dev/null | string trim)

    if test "$argv[1]" = "status"
        if test -n "$iface"
            echo "up ($iface)"
            sudo wg show $iface | grep -E 'peer|endpoint|latest handshake'
        else
            echo "down"
        end
        return 0
    end

    if test -n "$iface"
        sudo wg-quick down wg0
        echo "vpn down"
    else
        sudo wg-quick up wg0
        set -l up_iface (sudo wg show interfaces | string trim)
        set -l ip (ifconfig $up_iface | awk '/inet /{print $2}')
        echo "vpn up ($up_iface) $ip"
    end
end
