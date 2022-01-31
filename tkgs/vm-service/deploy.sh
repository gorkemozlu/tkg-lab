#!/bin/bash

ytt -f values.yaml -f sample-vm.yaml --ignore-unknown-comments| kubectl apply -f-