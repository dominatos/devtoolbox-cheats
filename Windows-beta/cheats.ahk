#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%

CHEATS_DIR = C:\Users\<USER>\cheats.d
LOG_FILE = C:\Users\<USER>\cheats_debug.log

; ============= Debug Log =============
FileDelete, %LOG_FILE%
FileAppend, Script started`n, %LOG_FILE%

; ============= Tray Setup =============
Menu, Tray, Tip, Dev Toolbox Cheats

; ============= Backups & S3 =============
Menu, BackupsS3, Add, s3cmd — S3 CLI, OpenFile
Menu, BackupsS3, Add, Borg Backup, OpenFile
Menu, BackupsS3, Add, Restic Backup, OpenFile

; ============= Basics =============
Menu, Basics, Add, Linux Basics — Cheatsheet, OpenFile
Menu, Basics, Add, Linux Basics 2 — Cheatsheet, OpenFile

; ============= Cloud =============
Menu, Cloud, Add, AWS CLI, OpenFile
Menu, Cloud, Add, Azure CLI, OpenFile
Menu, Cloud, Add, GCP CLI, OpenFile
Menu, Cloud, Add, OpenStack, OpenFile

; ============= Databases =============
Menu, Databases, Add, Memcached, OpenFile
Menu, Databases, Add, MongoDB, OpenFile
Menu, Databases, Add, MySQL/MariaDB && Cluster, OpenFile
Menu, Databases, Add, OpenSearch, OpenFile
Menu, Databases, Add, Oracle, OpenFile
Menu, Databases, Add, PostgreSQL, OpenFile
Menu, Databases, Add, Redis, OpenFile
Menu, Databases, Add, SQLite, OpenFile

; ============= Dev & Tools =============
Menu, DevTools, Add, Ansible, OpenFile
Menu, DevTools, Add, Build Tools, OpenFile
Menu, DevTools, Add, Git Advanced, OpenFile
Menu, DevTools, Add, Git, OpenFile
Menu, DevTools, Add, Jenkins, OpenFile
Menu, DevTools, Add, Kafka, OpenFile
Menu, DevTools, Add, Node Tools, OpenFile
Menu, DevTools, Add, Python Tools, OpenFile
Menu, DevTools, Add, Terraform, OpenFile
Menu, DevTools, Add, tmux, OpenFile
Menu, DevTools, Add, Zookeeper, OpenFile

; ============= Diagnostics =============
Menu, Diagnostics, Add, Diagnostics, OpenFile
Menu, Diagnostics, Add, Process Diagnostics, OpenFile

; ============= Files & Archives =============
Menu, FilesArchives, Add, diff && patch, OpenFile
Menu, FilesArchives, Add, tar, OpenFile
Menu, FilesArchives, Add, tar + zstd, OpenFile
Menu, FilesArchives, Add, zip/7z/zstd, OpenFile

; ============= Identity Management =============
Menu, IdentityMgmt, Add, AD CLI, OpenFile

; ============= Infrastructure Management =============
Menu, InfraMgmt, Add, AWX, OpenFile
Menu, InfraMgmt, Add, Uyuni, OpenFile

; ============= Kubernetes & Containers =============
Menu, K8s, Add, Docker, OpenFile
Menu, K8s, Add, Helm, OpenFile
Menu, K8s, Add, K9s, OpenFile
Menu, K8s, Add, kubectl, OpenFile
Menu, K8s, Add, kubectl JSONPath, OpenFile
Menu, K8s, Add, kubectl Kustomize, OpenFile
Menu, K8s, Add, OpenShift, OpenFile
Menu, K8s, Add, Podman && nerdctl, OpenFile

; ============= Monitoring =============
Menu, Monitoring, Add, Cerebro, OpenFile
Menu, Monitoring, Add, CheckMK Agent, OpenFile
Menu, Monitoring, Add, CheckMK, OpenFile
Menu, Monitoring, Add, Filebeat, OpenFile
Menu, Monitoring, Add, Nagios, OpenFile
Menu, Monitoring, Add, SNMPD, OpenFile
Menu, Monitoring, Add, Telegraf, OpenFile
Menu, Monitoring, Add, VictoriaMetrics, OpenFile
Menu, Monitoring, Add, Zabbix Server, OpenFile

; ============= Network =============
Menu, Network, Add, autossh — Resilient SSH Tunnels, OpenFile
Menu, Network, Add, CURL — HTTP Client, OpenFile
Menu, Network, Add, DNS — dig/nslookup/host, OpenFile
Menu, Network, Add, Fail2Ban — Intrusion Prevention, OpenFile
Menu, Network, Add, firewalld — Firewall Management, OpenFile
Menu, Network, Add, ip — Network Configuration, OpenFile
Menu, Network, Add, iptables — Firewall Rules, OpenFile
Menu, Network, Add, iptables to nftables Translation, OpenFile
Menu, Network, Add, nc / nmap — Network Tools, OpenFile
Menu, Network, Add, Network Diagnostics, OpenFile
Menu, Network, Add, netplan — Network Configuration, OpenFile
Menu, Network, Add, Network Backend Detection, OpenFile
Menu, Network, Add, NetworkManager, OpenFile
Menu, Network, Add, nftables — Modern Firewall, OpenFile
Menu, Network, Add, nmcli — NetworkManager CLI, OpenFile
Menu, Network, Add, resolvectl, OpenFile
Menu, Network, Add, RSYNC — File Synchronization, OpenFile
Menu, Network, Add, SCP — Secure Copy, OpenFile
Menu, Network, Add, SS — Socket Statistics, OpenFile
Menu, Network, Add, SSH — Commands && Config, OpenFile
Menu, Network, Add, SSH Tunneling && Port Forwarding, OpenFile
Menu, Network, Add, systemd-networkd, OpenFile
Menu, Network, Add, UFW — Uncomplicated Firewall, OpenFile
Menu, Network, Add, VPN Plugins, OpenFile
Menu, Network, Add, WireGuard — VPN Setup, OpenFile

; ============= Package Managers =============
Menu, PkgMgr, Add, AppImage — Portable Apps, OpenFile
Menu, PkgMgr, Add, APT — Debian/Ubuntu, OpenFile
Menu, PkgMgr, Add, DNF — RHEL/Fedora, OpenFile
Menu, PkgMgr, Add, Flatpak, OpenFile
Menu, PkgMgr, Add, Pacman — Arch Linux, OpenFile
Menu, PkgMgr, Add, Package Managers Overview, OpenFile
Menu, PkgMgr, Add, Snap — Universal Packages, OpenFile
Menu, PkgMgr, Add, Zypper — OpenSUSE, OpenFile

; ============= Security & Crypto =============
Menu, Security, Add, AIDE, OpenFile
Menu, Security, Add, Cerbero Suite, OpenFile
Menu, Security, Add, CrowdSec, OpenFile
Menu, Security, Add, Git Secret Leak Detection, OpenFile
Menu, Security, Add, GPG / age — Encryption, OpenFile
Menu, Security, Add, htpasswd — Basic Auth, OpenFile
Menu, Security, Add, OpenSSL — Commands, OpenFile
Menu, Security, Add, OpenSSL CSR with SAN, OpenFile
Menu, Security, Add, pass — Password Store, OpenFile
Menu, Security, Add, SSH Honeypot + CrowdSec, OpenFile
Menu, Security, Add, SSH Keys && Access Management, OpenFile

; ============= Storage & FS =============
Menu, StorageFS, Add, ACL, OpenFile
Menu, StorageFS, Add, Chroot, OpenFile
Menu, StorageFS, Add, Disk Growth, OpenFile
Menu, StorageFS, Add, LVM — Basics, OpenFile
Menu, StorageFS, Add, Partition && Mount, OpenFile
Menu, StorageFS, Add, SMART && mdadm RAID, OpenFile

; ============= System & Logs =============
Menu, SysLogs, Add, cron / at — Commands, OpenFile
Menu, SysLogs, Add, date && timedatectl, OpenFile
Menu, SysLogs, Add, du/df/lsof/ps, OpenFile
Menu, SysLogs, Add, ionice && nice, OpenFile
Menu, SysLogs, Add, journalctl — Basics, OpenFile
Menu, SysLogs, Add, journalctl — Systemd Journal, OpenFile
Menu, SysLogs, Add, Kernel-panic RHEL, OpenFile
Menu, SysLogs, Add, Kibana, OpenFile
Menu, SysLogs, Add, logrotate, OpenFile
Menu, SysLogs, Add, Ubuntu VPS Optimization, OpenFile
Menu, SysLogs, Add, SELinux && AppArmor, OpenFile
Menu, SysLogs, Add, systemctl — Commands, OpenFile
Menu, SysLogs, Add, systemd Timers, OpenFile
Menu, SysLogs, Add, systemd unit template, OpenFile

; ============= Text & Parsing =============
Menu, TextParsing, Add, AWK — Commands, OpenFile
Menu, TextParsing, Add, cut/sort/uniq, OpenFile
Menu, TextParsing, Add, FIND — Commands, OpenFile
Menu, TextParsing, Add, fzf — Fuzzy Finder, OpenFile
Menu, TextParsing, Add, GREP — Commands, OpenFile
Menu, TextParsing, Add, JQ — Commands, OpenFile
Menu, TextParsing, Add, Bash Loops, OpenFile
Menu, TextParsing, Add, Modern CLI, OpenFile
Menu, TextParsing, Add, SED — Commands, OpenFile
Menu, TextParsing, Add, Tree, OpenFile
Menu, TextParsing, Add, tr/head/tail/watch, OpenFile
Menu, TextParsing, Add, vim, OpenFile
Menu, TextParsing, Add, yq — YAML processor, OpenFile

; ============= Virtualization =============
Menu, Virtualization, Add, KVM / Libvirt, OpenFile

; ============= Web Servers =============
Menu, WebServers, Add, Apache HTTPD, OpenFile
Menu, WebServers, Add, HAProxy, OpenFile
Menu, WebServers, Add, Nginx, OpenFile
Menu, WebServers, Add, Tomcat, OpenFile
Menu, WebServers, Add, WebLogic Server, OpenFile

; ============= Main Tray Menu =============
Menu, Tray, Add, Backups & S3, :BackupsS3
Menu, Tray, Add, Basics, :Basics
Menu, Tray, Add, Cloud, :Cloud
Menu, Tray, Add, Databases, :Databases
Menu, Tray, Add, Dev & Tools, :DevTools
Menu, Tray, Add, Diagnostics, :Diagnostics
Menu, Tray, Add, Files & Archives, :FilesArchives
Menu, Tray, Add, Identity Management, :IdentityMgmt
Menu, Tray, Add, Infrastructure Management, :InfraMgmt
Menu, Tray, Add, Kubernetes & Containers, :K8s
Menu, Tray, Add, Monitoring, :Monitoring
Menu, Tray, Add, Network, :Network
Menu, Tray, Add, Package Managers, :PkgMgr
Menu, Tray, Add, Security & Crypto, :Security
Menu, Tray, Add, Storage & FS, :StorageFS
Menu, Tray, Add, System & Logs, :SysLogs
Menu, Tray, Add, Text & Parsing, :TextParsing
Menu, Tray, Add, Virtualization, :Virtualization
Menu, Tray, Add, Web Servers, :WebServers
Menu, Tray, Add,
Menu, Tray, Add, Open cheats folder, OpenFolder
Menu, Tray, Add, Exit, ExitApp

Menu, Tray, Icon, shell32.dll, 77

FileAppend, All menus built`n, %LOG_FILE%
return

; ============= File Map =============
FileMap(item) {
    static files := {}
    if (files.Count() = 0) {
        ; Backups & S3
        files["s3cmd — S3 CLI"]                       := "backups-s3\s3cmdcheatsheet.md"
        files["Borg Backup"]                           := "backups-s3\borgcheatsheet.md"
        files["Restic Backup"]                         := "backups-s3\resticcheatsheet.md"
        ; Basics
        files["Linux Basics — Cheatsheet"]             := "basics\linuxbasicscheatsheet.md"
        files["Linux Basics 2 — Cheatsheet"]           := "basics\linuxbasics2cheatsheet.md"
        ; Cloud
        files["AWS CLI"]                               := "cloud\awsclicheatsheet.md"
        files["Azure CLI"]                             := "cloud\azureclicheatsheet.md"
        files["GCP CLI"]                               := "cloud\gcpclicheatsheet.md"
        files["OpenStack"]                             := "cloud\openstackcheatsheet.md"
        ; Databases
        files["Memcached"]                             := "databases\memcached-sysadmin.md"
        files["MongoDB"]                               := "databases\mongodbcheatsheet.md"
        files["MySQL/MariaDB & Cluster"]               := "databases\mysqlcheatsheet.md"
        files["OpenSearch"]                            := "databases\opensearchcheatsheet.md"
        files["Oracle"]                                := "databases\oraclecheatsheet.md"
        files["PostgreSQL"]                            := "databases\postgrescheatsheet.md"
        files["Redis"]                                 := "databases\redis_prod_cheatsheet.md"
        files["SQLite"]                                := "databases\sqlitecheatsheet.md"
        ; Dev & Tools
        files["Ansible"]                               := "dev-tools\ansiblecheatsheet.md"
        files["Build Tools"]                           := "dev-tools\buildtoolscheatsheet.md"
        files["Git Advanced"]                          := "dev-tools\gitadvancedcheatsheet.md"
        files["Git"]                                   := "dev-tools\gitcheatsheet.md"
        files["Jenkins"]                               := "dev-tools\jenkinscheatsheet.md"
        files["Kafka"]                                 := "dev-tools\kafkacheatsheet.md"
        files["Node Tools"]                            := "dev-tools\nodetoolscheatsheet.md"
        files["Python Tools"]                          := "dev-tools\pythontoolscheatsheet.md"
        files["Terraform"]                             := "dev-tools\terraformcheatsheet.md"
        files["tmux"]                                  := "dev-tools\tmuxcheatsheet.md"
        files["Zookeeper"]                             := "dev-tools\zookeepercheatsheet.md"
        ; Diagnostics
        files["Diagnostics"]                           := "diagnostics\diagcheatsheet.md"
        files["Process Diagnostics"]                   := "diagnostics\process_diagnostics_cheatsheet.md"
        ; Files & Archives
        files["diff & patch"]                          := "files-archives\diffpatchcheatsheet.md"
        files["tar"]                                   := "files-archives\tarcheatsheet.md"
        files["tar + zstd"]                            := "files-archives\tarzstdcheatsheet.md"
        files["zip/7z/zstd"]                           := "files-archives\zip7zzstdcheatsheet.md"
        ; Identity Management
        files["AD CLI"]                                := "identity-management\adclicheatsheet.md"
        ; Infrastructure Management
        files["AWX"]                                   := "infrastructure-mgmt\awxcheatsheet.md"
        files["Uyuni"]                                 := "infrastructure-mgmt\uyunicheatsheet.md"
        ; Kubernetes & Containers
        files["Docker"]                                := "kubernetes-containers\dockercheatsheet.md"
        files["Helm"]                                  := "kubernetes-containers\helmcheatsheet.md"
        files["K9s"]                                   := "kubernetes-containers\k9scheatsheet.md"
        files["kubectl"]                               := "kubernetes-containers\kubectlcheatsheet.md"
        files["kubectl JSONPath"]                      := "kubernetes-containers\kubectljsonpathcheatsheet.md"
        files["kubectl Kustomize"]                     := "kubernetes-containers\kubectlkustomizecheatsheet.md"
        files["OpenShift"]                             := "kubernetes-containers\openshiftcheatsheet.md"
        files["Podman & nerdctl"]                      := "kubernetes-containers\podmannerdctlcheatsheet.md"
        ; Monitoring
        files["Cerebro"]                               := "monitoring\cerebrocheatsheet.md"
        files["CheckMK Agent"]                         := "monitoring\checkmkagentcheatsheet.md"
        files["CheckMK"]                               := "monitoring\checkmkcheatsheet.md"
        files["Filebeat"]                              := "monitoring\filebeatcheatsheet.md"
        files["Nagios"]                                := "monitoring\nagioscheatsheet.md"
        files["SNMPD"]                                 := "monitoring\snmpdcheatsheet.md"
        files["Telegraf"]                              := "monitoring\telegrafcheatsheet.md"
        files["VictoriaMetrics"]                       := "monitoring\victoriametricscheatsheet.md"
        files["Zabbix Server"]                         := "monitoring\zabbixcheatsheet.md"
        ; Network
        files["autossh — Resilient SSH Tunnels"]       := "network\autosshcheatsheet.md"
        files["CURL — HTTP Client"]                    := "network\curlcheatsheet.md"
        files["DNS — dig/nslookup/host"]               := "network\dnscheatsheet.md"
        files["Fail2Ban — Intrusion Prevention"]       := "network\fail2bancheatsheet.md"
        files["firewalld — Firewall Management"]       := "network\firewalldcheatsheet.md"
        files["ip — Network Configuration"]            := "network\ipcheatsheet.md"
        files["iptables — Firewall Rules"]             := "network\iptablescheatsheet.md"
        files["iptables to nftables Translation"]      := "network\iptablesnfttranslatecheatsheet.md"
        files["nc / nmap — Network Tools"]             := "network\ncnmapcheatsheet.md"
        files["Network Diagnostics"]                   := "network\netdiagcheatsheet.md"
        files["netplan — Network Configuration"]       := "network\netplancheatsheet.md"
        files["Network Backend Detection"]             := "network\network-backend-detectioncheatsheet.md"
        files["NetworkManager"]                        := "network\networkmanagercheatsheet.md"
        files["nftables — Modern Firewall"]            := "network\nftcheatsheet.md"
        files["nmcli — NetworkManager CLI"]            := "network\nmclicheatsheet.md"
        files["resolvectl"]                            := "network\resolvectlcheatsheet.md"
        files["RSYNC — File Synchronization"]          := "network\rsynccheatsheet.md"
        files["SCP — Secure Copy"]                     := "network\scpcheatsheet.md"
        files["SS — Socket Statistics"]                := "network\sscheatsheet.md"
        files["SSH — Commands & Config"]               := "network\sshcheatsheet.md"
        files["SSH Tunneling & Port Forwarding"]       := "network\ssh_vpn_tunnel_cheatsheet.md"
        files["systemd-networkd"]                      := "network\systemd-networkdcheatsheet.md"
        files["UFW — Uncomplicated Firewall"]          := "network\ufwcheatsheet.md"
        files["VPN Plugins"]                           := "network\vpn-pluginscheatsheet.md"
        files["WireGuard — VPN Setup"]                 := "network\wireguardcheatsheet.md"
        ; Package Managers
        files["AppImage — Portable Apps"]              := "package-managers\appimagecheatsheet.md"
        files["APT — Debian/Ubuntu"]                   := "package-managers\aptcheatsheet.md"
        files["DNF — RHEL/Fedora"]                     := "package-managers\dnfcheatsheet.md"
        files["Flatpak"]                               := "package-managers\flatpakcheatsheet.md"
        files["Pacman — Arch Linux"]                   := "package-managers\pacmancheatsheet.md"
        files["Package Managers Overview"]             := "package-managers\pkgmanagerscheatsheet.md"
        files["Snap — Universal Packages"]             := "package-managers\snapcheatsheet.md"
        files["Zypper — OpenSUSE"]                     := "package-managers\zyppercheatsheet.md"
        ; Security & Crypto
        files["AIDE"]                                  := "security-crypto\aidecheatsheet.md"
        files["Cerbero Suite"]                         := "security-crypto\cerberocheatsheet.md"
        files["CrowdSec"]                              := "security-crypto\crowdseccheatsheet.md"
        files["Git Secret Leak Detection"]             := "security-crypto\gitleakscheatsheet.md"
        files["GPG / age — Encryption"]                := "security-crypto\gpgagecheatsheet.md"
        files["htpasswd — Basic Auth"]                 := "security-crypto\htpasswdcheatsheet.md"
        files["OpenSSL — Commands"]                    := "security-crypto\opensslcheatsheet.md"
        files["OpenSSL CSR with SAN"]                  := "security-crypto\opensslsancsrcheatsheet.md"
        files["pass — Password Store"]                 := "security-crypto\passcheatsheet.md"
        files["SSH Honeypot + CrowdSec"]               := "security-crypto\ssh_honeypot_crowdsec.md"
        files["SSH Keys & Access Management"]          := "security-crypto\ssh_keys_cheatsheet.md"
        ; Storage & FS
        files["ACL"]                                   := "storage-fs\aclcheatsheet.md"
        files["Chroot"]                                := "storage-fs\chrootcheatsheet.md"
        files["Disk Growth"]                           := "storage-fs\diskgrowcheatsheet.md"
        files["LVM — Basics"]                          := "storage-fs\lvmcheatsheet.md"
        files["Partition & Mount"]                     := "storage-fs\partitionmountcheatsheet.md"
        files["SMART & mdadm RAID"]                    := "storage-fs\smartraidcheatsheet.md"
        ; System & Logs
        files["cron / at — Commands"]                  := "system-logs\cronatcheatsheet.md"
        files["date & timedatectl"]                    := "system-logs\datetzcheatsheet.md"
        files["du/df/lsof/ps"]                         := "system-logs\diskproccheatsheet.md"
        files["ionice & nice"]                         := "system-logs\ionicenicescheatsheet.md"
        files["journalctl — Basics"]                   := "system-logs\journalctlbasicscheatsheet.md"
        files["journalctl — Systemd Journal"]          := "system-logs\journalctlcheatsheet.md"
        files["Kernel-panic RHEL"]                     := "system-logs\kernelpanicscheatsheet.md"
        files["Kibana"]                                := "system-logs\kibanacheatsheet.md"
        files["logrotate"]                             := "system-logs\logrotatecheatsheet.md"
        files["Ubuntu VPS Optimization"]               := "system-logs\optimize-vps-ubuntu.md"
        files["SELinux & AppArmor"]                    := "system-logs\selinuxapparmorcheatsheet.md"
        files["systemctl — Commands"]                  := "system-logs\systemctlcheatsheet.md"
        files["systemd Timers"]                        := "system-logs\systemdtimerscheatsheet.md"
        files["systemd unit template"]                 := "system-logs\systemdunittemplate.md"
        ; Text & Parsing
        files["AWK — Commands"]                        := "text-parsing\awkcheatsheet.md"
        files["cut/sort/uniq"]                         := "text-parsing\cutsortuniqcheatsheet.md"
        files["FIND — Commands"]                       := "text-parsing\findcheatsheet.md"
        files["fzf — Fuzzy Finder"]                    := "text-parsing\fzfcheatsheet.md"
        files["GREP — Commands"]                       := "text-parsing\grepcheatsheet.md"
        files["JQ — Commands"]                         := "text-parsing\jqcheatsheet.md"
        files["Bash Loops"]                            := "text-parsing\loopscheatsheet.md"
        files["Modern CLI"]                            := "text-parsing\modernclicheatsheet.md"
        files["SED — Commands"]                        := "text-parsing\sedcheatsheet.md"
        files["Tree"]                                  := "text-parsing\treecheatsheet.md"
        files["tr/head/tail/watch"]                    := "text-parsing\trheadtailwatchcheatsheet.md"
        files["vim"]                                   := "text-parsing\vimquickstartcheatsheet.md"
        files["yq — YAML processor"]                   := "text-parsing\yqcheatsheet.md"
        ; Virtualization
        files["KVM / Libvirt"]                         := "virtualization\kvmcheatsheet.md"
        ; Web Servers
        files["Apache HTTPD"]                          := "web-servers\apachecheatsheet.md"
        files["HAProxy"]                               := "web-servers\haproxycheatsheet.md"
        files["Nginx"]                                 := "web-servers\nginxcheatsheet.md"
        files["Tomcat"]                                := "web-servers\tomcatcheatsheet.md"
        files["WebLogic Server"]                       := "web-servers\weblogiccheatsheet.md"
    }
    return files[item]
}

OpenFile:
    item := A_ThisMenuItem
    FileAppend, OpenFile called: %item%`n, %LOG_FILE%
    rel := FileMap(item)
    FileAppend, Rel: %rel%`n, %LOG_FILE%
    if (rel != "") {
        path := CHEATS_DIR . "\" . rel
        FileAppend, Path: %path%`n, %LOG_FILE%
        Run, %path%
    }
return

OpenFolder:
    Run, %CHEATS_DIR%
return

ExitApp:
    ExitApp
return
