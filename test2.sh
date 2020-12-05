#!/bin/bash
if [ -e /proc/$1 ]
then
    echo "ok"
else
    echo "nok"
fi