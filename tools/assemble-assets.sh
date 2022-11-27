cd ../
mkdir -p tmp/{pc,psp,nx,vita,3ds,nzp}
cp -r common/* tmp/nzp/
cp -r psp/* tmp/psp/
cp -r tmp/nzp/* tmp/psp/nzportable/nzp/
cd tmp/psp/
zip -r ../psp-nzp-assets.zip ./*
cd ../../
cp -r nx/* tmp/nx/
cp -r tmp/nzp/* tmp/nx/nzportable/nzp/
cd tmp/nx/
zip -r ../nx-nzp-assets.zip ./*
cd ../../
cp -r vita/* tmp/vita/
cp -r tmp/nzp/* tmp/vita/data/nzp/nzp/
cd tmp/vita/
zip -r ../vita-nzp-assets.zip ./*
cd ../../
cp -r 3ds/* tmp/3ds/
cp -r tmp/nzp/* tmp/3ds/nzportable/nzp/
cd tmp/3ds/
zip -r ../3ds-nzp-assets.zip ./*
cd ../../
cp -r pc/* tmp/pc/
cp -r tmp/nzp/* tmp/pc/nzp/
cd tmp/pc/
zip -r ../pc-nzp-assets.zip ./*