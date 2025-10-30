#!/usr/bin/env bash

filename=$(basename $1)
typst compile $filename --font-path=../fonts/firacode/
