# PPTP Server in Docker

A containerized legacy PPTP server based on Debian and `pptpd`, with nftables rules for forwarding and NAT.

> [!WARNING]
> **PPTP is not considered secure and should not be used to protect sensitive traffic.**
> PPTP commonly relies on MS-CHAPv2, which has known cryptographic weaknesses. This repository's configuration also enables `noccp` and does not negotiate MPPE encryption. Treat this project as a legacy compatibility example, not as a secure VPN.
>
> For new deployments, use a modern VPN such as WireGuard, OpenVPN, or IKEv2/IPsec.

## Features

- Debian-based container image
- `pptpd` server
- nftables rules for forwarding, NAT, and TCP MSS adjustment
- Host networking for PPTP and GRE traffic

## Requirements

- A Linux host with Docker Engine and Docker Compose
- An upstream network and host firewall that allow:
  - TCP port `1723`
  - GRE, IP protocol `47` (not TCP or UDP port 47)
- A free VPN subnet that does not overlap with the host LAN or other VPN networks

The container uses host networking and runs with elevated privileges because it changes host networking settings and nftables rules. Run it only on a host you trust. Docker documents that privileged containers receive broad access to host devices and capabilities. <citation src="6"></citation>

## Configuration

The checked-in configuration uses:

- VPN subnet: `10.99.99.0/24`
- Server-side tunnel address: `10.99.99.1`
- Client address pool: `10.99.99.100-200`
- PPP MTU and MRU: `1358`
- TCP MSS: `1318`

Keep the subnet in `etc/pptpd.conf` and the nftables rules in `entrypoint.sh` consistent if you change the VPN address range.

Before starting the container:

1. Create the host configuration directory and copy the configuration files:

   ```sh
   sudo install -d -m 700 /etc/pptp
   sudo cp etc/pptpd.conf /etc/pptp/pptpd.conf
   sudo cp etc/ppp/options /etc/pptp/options
   sudo cp etc/ppp/pptpd-options /etc/pptp/pptpd-options
   sudo install -m 600 /dev/null /etc/pptp/chap-secrets
   ```

2. Add a user to `/etc/pptp/chap-secrets`:

   ```text
   # client  server  secret                    IP addresses
   alice    pptpd   REPLACE_WITH_A_STRONG_SECRET *
   ```

   Replace the placeholder with a unique secret. Keep this file readable only by root:

   ```sh
   sudo chmod 600 /etc/pptp/chap-secrets
   ```

3. Ensure `compose.yaml` mounts the PPTP options file at the path used by `pptpd.conf`:

   ```yaml
   - /etc/pptp/pptpd-options:/etc/ppp/pptpd-options
   ```

   The `option` directive in `pptpd.conf` points to `/etc/ppp/pptpd-options`.

## Build and run

Build the image from the repository root:

```sh
docker build -f Containerfile -t typhoonchik/pptpd .
```

Start the service:

```sh
sudo docker compose up -d
sudo docker compose logs -f pptpd
```

The container enables IPv4 forwarding and installs its nftables table on the host. Check the host firewall as well: it must permit incoming TCP port `1723` and GRE protocol `47`. The Dockerfile's `EXPOSE 1723/tcp` does not replace host firewall rules when using host networking.

## License

MIT
