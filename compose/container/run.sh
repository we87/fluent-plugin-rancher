#!/bin/bash

wait_for_es() {
    while ! curl -qsL --fail http://elasticsearch:9200 >/dev/null ; do
        echo "Waiting for elasticsearch"
        sleep 2
    done
    echo "done!"
}

wait_for_es

exec "$@"
