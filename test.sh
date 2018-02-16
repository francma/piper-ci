#!/bin/sh
set -eu

PIPER_HOME='/home/anon/skola'
DATABASE_FILE="/tmp/default.db"
PIPER_CORE_PORT=5000
PIPER_WEB_PORT=5001

echo "FLUSHALL" | redis-cli -n 12
rm -rf "$DATABASE_FILE"
rm -rf "$PIPER_HOME/piper-jobs"
mkdir "$PIPER_HOME/piper-jobs"
killall uwsgi || true
killall piper-lxd || true

cd "$PIPER_HOME/piper-ci-driver"
python "./setup.py" develop
# init database
piper-core "$PIPER_HOME/piper-ci/core.yml" --init "root@localhost.com ~/.ssh/id_rsa.pub"

# start piper-core
uwsgi --http-socket :$PIPER_CORE_PORT -w piper_core.run:app --pyargv "$PIPER_HOME/piper-ci/core.yml" 1>&2 2>"$PIPER_HOME/piper-ci/core.log" &

# get user token
TOKEN=$(echo 'SELECT token FROM user WHERE id = 1;' | sqlite3 "$DATABASE_FILE")
echo "$TOKEN" | xclip -selection c
cd -

cd "$PIPER_HOME/piper-ci-web"
python "./setup.py" develop

uwsgi --http-socket :$PIPER_WEB_PORT -w piper_web.run:app --pyargv "$PIPER_HOME/piper-ci/web.yml" 1>&2 2>"$PIPER_HOME/piper-ci/web.log" &
cd -

cd "$PIPER_HOME/piper-ci-lxd-runner"
python "./setup.py" develop

# start
piper-lxd "$PIPER_HOME/piper-ci/lxd.yml" 1>&2 2>"$PIPER_HOME/piper-ci/lxd.log" &
cd -

cd "$PIPER_HOME/piper-ci-driver"
# create project
curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -X POST -d '{"url":"https://github.com/francma/test","origin":"https://github.com/francma/test.git"}' http://localhost:$PIPER_CORE_PORT/projects
curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -X POST -d '{"token": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","group":"all"}' http://localhost:$PIPER_CORE_PORT/runners
curl -H "Content-Type: application/json" -X POST -d "@$PIPER_HOME/piper-ci/hook.json" http://localhost:$PIPER_CORE_PORT/webhook
# curl -H "Content-Type: application/json" -X POST -d "@$PIPER_HOME/piper-ci/hook.json" http://localhost:$PIPER_CORE_PORT/webhook
cd -


cd "$PIPER_HOME/piper-ci-driver"
piper-shell "$PIPER_HOME/piper-ci/core.yml" 1
cd -
