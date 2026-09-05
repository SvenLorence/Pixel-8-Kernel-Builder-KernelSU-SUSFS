#!/usr/bin/env bash
set -euo pipefail

FEATURE_PATCHES_DIR="${PROJECT_ROOT}/patches/kernel_patches/common"

if [[ ! -d "${FEATURE_PATCHES_DIR}" || ! -f "${FEATURE_PATCHES_DIR}/fake_config.patch" ]]; then
  log "Initializing kernel_patches submodule..."
  git -C "${PROJECT_ROOT}" submodule update --init --recursive patches/kernel_patches
fi

# ==============================================================================
#                        APPLY EXTRA KERNEL PATCHES
# ==============================================================================

log "Applying extra kernel patches (features)"

FEATURE_PATCHES=(
  "fake_config.patch"                       # Фильтрация опций CONFIG_KSU в /proc/config.gz
  "optimise_memcmp.patch"                   # ARM64 NEON SIMD ускорение memcmp
  "file_struct_8bytes_align.patch"          # Выравнивание struct file по 8 байтам для кэша
  "f2fs_enlarge_min_fsync_blocks.patch"     # Увеличение батча fsync с 8 до 20 блоков в F2FS
  "silence_system_logspam.patch"            # Подавление спама healthd/logd/dashd в dmesg
  "silence_irq_cpu_logspam.patch"           # Подавление предупреждений миграции IRQ в dmesg
)

for patch_name in "${FEATURE_PATCHES[@]}"; do
  apply_patch_file "${AOSP}" "${FEATURE_PATCHES_DIR}/${patch_name}"
done

# Configure fake_config to hide KSU/SUSFS options dynamically from Kconfig
if [[ "${KSU_TYPE}" != "None" ]]; then
  for kconfig_file in "${AOSP}/KernelSU/kernel/Kconfig" "${AOSP}/KernelSU-Next/kernel/Kconfig"; do
    [[ -f "${kconfig_file}" ]] && break
  done

  if [[ -f "${kconfig_file}" ]]; then
    mapfile -t FAKE_DISABLE_CONFIGS < <(grep -E '^[[:space:]]*config[[:space:]]+' "${kconfig_file}" | awk '{print "CONFIG_" $2}')

    log "Parsed KSU/SUSFS configs to hide in fake_config (${kconfig_file#$AOSP/}):"
    for cfg in "${FAKE_DISABLE_CONFIGS[@]}"; do
      printf '  - %s\n' "$cfg"
    done

    if grep -q "CONFIG_FAKE_DISABLE ?=" "${AOSP}/kernel/Makefile"; then
      # Передаем спарсенный список опций KSU/SUSFS в переменную CONFIG_FAKE_DISABLE Makefile
      sed -i "s/CONFIG_FAKE_DISABLE ?=/CONFIG_FAKE_DISABLE ?= ${FAKE_DISABLE_CONFIGS[*]}/" "${AOSP}/kernel/Makefile"
      # Меняем логику fake_config: полностью вырезаем строки опций (/d) вместо замены на 'is not set'
      sed -i 's|^KCONFIG_CONFIG_PATCHED :=.*|KCONFIG_CONFIG_PATCHED := $(shell sed $(foreach opt,$(CONFIG_OPTIONS_LIST),-e '\''/^$(opt)=/d'\'' -e '\''/^# $(opt) is not set/d'\'') $(KCONFIG_CONFIG) > .config.patched \&\& echo ".config.patched")|' "${AOSP}/kernel/Makefile"
    fi
  fi
fi

# ==============================================================================
#                     NETWORKING & PERFORMANCE DEFCONFIGS
# ==============================================================================

log "Configuring extra networking and optimization defconfig options"

tee -a "${GKI_DEFCONFIG}" "${DEVICE_DEFCONFIG}" > /dev/null << 'EOF'
# IP Set & Firewall Configs
CONFIG_IP_SET=y
CONFIG_IP_SET_MAX=65534
CONFIG_IP_SET_BITMAP_IP=y
CONFIG_IP_SET_BITMAP_IPMAC=y
CONFIG_IP_SET_BITMAP_PORT=y
CONFIG_IP_SET_HASH_IP=y
CONFIG_IP_SET_HASH_IPMARK=y
CONFIG_IP_SET_HASH_IPPORT=y
CONFIG_IP_SET_HASH_IPPORTIP=y
CONFIG_IP_SET_HASH_IPPORTNET=y
CONFIG_IP_SET_HASH_IPMAC=y
CONFIG_IP_SET_HASH_MAC=y
CONFIG_IP_SET_HASH_NETPORTNET=y
CONFIG_IP_SET_HASH_NET=y
CONFIG_IP_SET_HASH_NETNET=y
CONFIG_IP_SET_HASH_NETPORT=y
CONFIG_IP_SET_HASH_NETIFACE=y
CONFIG_IP_SET_LIST_SET=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_NETFILTER_XT_SET=y
CONFIG_NETFILTER_XT_TARGET_LOG=y
CONFIG_NETFILTER_XT_MATCH_RECENT=y
CONFIG_IP6_NF_NAT=y
CONFIG_IP6_NF_TARGET_MASQUERADE=y

# TCP Congestion Control Configs
CONFIG_TCP_CONG_ADVANCED=y
CONFIG_TCP_CONG_BBR=y
CONFIG_TCP_CONG_CUBIC=y
CONFIG_TCP_CONG_BIC=y
CONFIG_TCP_CONG_WESTWOOD=y
CONFIG_TCP_CONG_HTCP=y
CONFIG_DEFAULT_BBR=y
CONFIG_DEFAULT_TCP_CONG="bbr"

# Traffic Shaping (Qdisc) Configs
CONFIG_NET_SCH_FQ=y
CONFIG_NET_SCH_FQ_CODEL=y
CONFIG_NET_SCH_CAKE=y

# Connection Marking Configs
CONFIG_NET_ACT_CONNMARK=y

# TTL/Hop Limit Target Configs
CONFIG_IP_NF_TARGET_TTL=y
CONFIG_IP6_NF_TARGET_HL=y
CONFIG_IP6_NF_MATCH_HL=y

# Wireguard VPN Configs
CONFIG_WIREGUARD=y
EOF
