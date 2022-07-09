#!/bin/bash
echo "$(date) $(whoami)" >>~/Desktop/askpass.log
echo '{{ ansible_become_pass }}'
