#!/bin/bash

set -e
set -x

image=docker-registry:5000/testnetz/base-image

docker build -t ${image} .

echo "Base-Image gebaut!"
echo "Wenn Tests abgeschlossen, hochladen mit: 'docker push ${image}'"
