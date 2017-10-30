#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Make sure required directories exist.
mkdir -p /config/bin
mkdir -p /config/log
mkdir -p /config/cache
mkdir -p /config/var

# Install default config if needed.
if [ ! -d /config/conf ]
then
  cp -pr $CRASHPLAN_DIR/conf.default /config/conf
fi

# Install default run.conf if needed.
[ -f /config/bin/run.conf ] || cp $CRASHPLAN_DIR/bin/run.conf.default /config/bin/run.conf

# Update CrashPlan Engine max memory if needed.
if [ "${CRASHPLAN_SRV_MAX_MEM:-UNSET}" != "UNSET" ]; then
  if ! echo "$CRASHPLAN_SRV_MAX_MEM" | grep -q "^[0-9]\+[g|G|m|M|k|K]\?$"
  then
    echo "ERROR: Invalid value for CRASHPLAN_SRV_MAX_MEM variable: '$CRASHPLAN_SRV_MAX_MEM'"
    exit 1
  fi

  CUR_MEM_VAL="$(cat /config/bin/run.conf | sed -n 's/.*SRV_JAVA_OPTS=.* -Xmx\([0-9]\+[g|G|m|M|k|K]\?\) .*$/\1/p')"
  if [ "$CRASHPLAN_SRV_MAX_MEM" != "$CUR_MEM_VAL" ]
  then
    echo "Updating CrashPlan Engine maximum memory from $CUR_MEM_VAL to $CRASHPLAN_SRV_MAX_MEM."
    sed -i "s/^\(SRV_JAVA_OPTS=.* -Xmx\)[0-9]\+[g|G|m|M|k|K]\? /\1$CRASHPLAN_SRV_MAX_MEM /" /config/bin/run.conf
  fi
fi

# Clear some log files.
rm -f /config/log/engine_output.log \
      /config/log/engine_error.log \
      /config/log/ui_output.log \
      /config/log/ui_error.log

# Make sure monitored log files exist.
for LOGFILE in /config/log/service.log.0 /config/log/app.log
do
    [ -f "$LOGFILE" ] || touch "$LOGFILE"
done

# Adjust ownership of /config.
chown -R $USER_ID:$GROUP_ID /config
# Adjust ownership of /backupArchives.
chown -R $USER_ID:$GROUP_ID /backupArchives

# vim: set ft=sh :
