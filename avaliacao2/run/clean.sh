#!/bin/bash

rm -f error*
rm -f core

# change 0x610661c3 to your semaphore and shared memory key
ipcrm -S 0x610519bb
ipcrm -M 0x610519bb

