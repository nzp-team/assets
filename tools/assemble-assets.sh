#!/usr/bin/env bash

set -o errexit

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$(cd ${SCRIPT_DIR}/../ && pwd)

cd "${SCRIPT_DIR}"

# Make generics 
cd ../
mkdir -p tmp/{pc,psp,nx,vita,ctr,nzp,nspire}
cp -r common/* tmp/nzp/

## Make PSP 
cd ${ROOT_DIR}
cp -r psp/* tmp/psp/
cp -r tmp/nzp/* tmp/psp/nzportable/nzp/
cd tmp/psp/
zip -r ../psp-nzp-assets.zip ./*

## Make Switch
cd ${ROOT_DIR}
cp -r nx/* tmp/nx/
cp -r tmp/nzp/* tmp/nx/nzportable/nzp/
cd tmp/nx/
zip -r ../nx-nzp-assets.zip ./*

## Make Vita 
cd ${ROOT_DIR}
cp -r vita/* tmp/vita/
cp -r tmp/nzp/* tmp/vita/data/nzp/nzp/
cd tmp/vita/
zip -r ../vita-nzp-assets.zip ./*

## Make 3DS 
cd ${ROOT_DIR}
cp -r ctr/* tmp/ctr/
cp -r tmp/nzp/* tmp/ctr/nzportable/nzp/
cd tmp/ctr/
zip -r ../3ds-nzp-assets.zip ./*

## Make PC
cd ${ROOT_DIR}
cp -r pc/* tmp/pc/
cp -r tmp/nzp/* tmp/pc/nzp/
cd tmp/pc/
zip -r ../pc-nzp-assets.zip ./*

## Make NSPIRE
cd ${ROOT_DIR}
cp -r nspire/* tmp/nspire/
cp -r tmp/nzp/* tmp/nspire/nzp/
cd tmp/nspire/

# naievil -- We don't need any sounds or tracks on NSPIRE as there is no sound processing
rm -rf nzp/sounds nzp/tracks 
# naievil -- We also need to create the PAK file from our assets now 
python3 ${ROOT_DIR}/tools/build-pak.py -v --input ${ROOT_DIR}/tmp/nspire/nzp --output ${ROOT_DIR}/tmp/nspire/nzp.pak.tns

# No need to keep any assets besides the PAK file
rm -rf nzp/*
mv ${ROOT_DIR}/tmp/nspire/nzp.pak.tns nzp/
zip -r ../nspire-nzp-assets.zip ./*