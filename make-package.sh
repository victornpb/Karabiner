#!/bin/sh

version=$(cat version)

packagemaker=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
pkgName="KeyRemap4MacBook.pkg"
archiveName="KeyRemap4MacBook-${version}.pkg.zip"

make clean build || exit $?

# --------------------------------------------------
# http://developer.apple.com/documentation/Darwin/Conceptual/KEXTConcept/KEXTConceptPackaging/packaging_kext.html
echo "Copy Files"

sudo rm -rf pkgroot
sudo mkdir -p pkgroot

basedir="/Library/org.pqrs/KeyRemap4MacBook"
sudo mkdir -p "pkgroot/$basedir"
sudo cp -R src/core/kext/build/Release/KeyRemap4MacBook.kext "pkgroot/$basedir"
sudo cp -R files/scripts "pkgroot/$basedir"

sudo mkdir -p "pkgroot/$basedir/prefpane"
sudo cp files/prefpane/number.xml files/prefpane/output/checkbox.xml "pkgroot/$basedir/prefpane"

sudo mkdir -p "pkgroot/$basedir/extra"
sudo cp -R pkginfo/Resources/preflight "pkgroot/$basedir/extra/uninstall_core.sh"
sudo cp -R files/extra/launchUninstaller.sh "pkgroot/$basedir/extra/"
sudo cp -R files/extra/uninstall.sh "pkgroot/$basedir/extra/"

sudo mkdir -p "pkgroot/Library"
sudo cp -R files/LaunchDaemons pkgroot/Library
sudo cp -R files/LaunchAgents pkgroot/Library

sudo mkdir -p "pkgroot/$basedir/app"
sudo cp -R "src/core/server/build/Release/KeyRemap4MacBook.app" "pkgroot/$basedir/app"
sudo cp -R "src/util/KeyDump/build/Release/KeyDump.app" "pkgroot/$basedir/app"
sudo cp -R "src/util/multitouchextension/build/Release/KeyRemap4MacBook_multitouchextension.app" "pkgroot/$basedir/app"
sudo cp -R "src/util/cli/build/Release/KeyRemap4MacBook_cli.app" "pkgroot/$basedir/app"
sudo cp -R "src/util/uninstaller/build/Release/uninstaller.app" "pkgroot/$basedir/app"

sudo mkdir -p "pkgroot/Library/PreferencePanes"
sudo cp -R "src/util/prefpane/build/Release/KeyRemap4MacBook.prefPane" "pkgroot/Library/PreferencePanes"

sudo find pkgroot -type d -print0 | xargs -0 sudo chmod 755
sudo find pkgroot -type f -print0 | xargs -0 sudo chmod 644
sudo find pkgroot -type l -print0 | xargs -0 sudo chmod -h 755
sudo find pkgroot -name '*.sh' -print0 | xargs -0 sudo chmod 755
for file in `sudo find pkgroot -type f`; do
    if ./pkginfo/is-mach-o.sh "$file"; then
        sudo chmod 755 "$file"
    fi
done
sudo chown -R root:wheel pkgroot

sudo chmod 1775 pkgroot/Library
sudo chown root:admin pkgroot/Library

# --------------------------------------------------
echo "Exec PackageMaker"

sudo rm -rf $pkgName
sudo $packagemaker \
    --root pkgroot \
    --info pkginfo/Info.plist \
    --resources pkginfo/Resources \
    --title "KeyRemap4MacBook $version" \
    --no-recommend \
    --no-relocate \
    --out $pkgName

# --------------------------------------------------
echo "Make Archive"

sudo chown -R root:wheel $pkgName
sudo zip -r $archiveName $pkgName
sudo rm -rf $pkgName
sudo chmod 644 $archiveName
unzip $archiveName

# --------------------------------------------------
echo "Cleanup"
sudo rm -rf pkgroot
make -C src clean
