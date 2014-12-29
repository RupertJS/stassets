#!/bin/bash


for file in {{all,print,screen,vendors}.css,{application,templates,vendors}.js}{,.map} ; do
  echo $file
  curl $HOSTNAME:8989/$file > fixtures/$file
done
