#!/bin/sh

lspci -nnk | grep -i net -A2
