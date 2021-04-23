CONSUL_SVC=$(systemctl status consul | grep 'Active:' | awk -F': ' '{$1=""; print $0}' | awk -F';' '{print $1}' | xargs)
VAULT_SVC=$(systemctl status vault | grep 'Active:' | awk -F': ' '{$1=""; print $0}' | awk -F';' '{print $1}' | xargs)

echo -e "===== SERVICES ===============================================================
 $COLOR_COLUMN- consul$RESET_COLORS.............: $COLOR_VALUE ${CONSUL_SVC}$RESET_COLORS
 $COLOR_COLUMN- vault (server)$RESET_COLORS.....: $COLOR_VALUE ${VAULT_SVC}$RESET_COLORS"
