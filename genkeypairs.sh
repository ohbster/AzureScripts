#!/bin/bash

function genkeypairs(){
    if [ $# -eq 1 ]; then
        local keyname=$1
        echo -e "$keyname-keypair"
    else
        echo "genkeypairs requires a name as argument"
        exit 1
    fi

}