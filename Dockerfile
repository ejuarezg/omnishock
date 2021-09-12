# Build image:
# podman build -t raspi1-bplus-gnu-omnishock -f Dockerfile

FROM localhost/raspi1-bplus-gnueabihf-toolchain

RUN dpkg --add-architecture armhf \
    && apt-get update \
    && cd /opt \
    # The first four packages are required to populate the folder /opt/vc. See
    # https://raspberrypi.stackexchange.com/questions/78719/missing-libbcm-host-so-when-running-chromium-browser/78740#78740
    && PACKAGES="libraspberrypi0:armhf libraspberrypi-dev:armhf libraspberrypi-doc:armhf libraspberrypi-bin:armhf libsdl2-dev:armhf liblz4-1:armhf libgcrypt20:armhf" \
    # The next three lines were nabbed from
    # https://stackoverflow.com/questions/13756800/how-to-download-all-dependencies-and-packages-to-directory/45489718#45489718
    && apt-get download $(apt-cache depends --recurse --no-recommends \
        --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances \
        --no-pre-depends ${PACKAGES} | grep "^\w") \
    # The next eight lines were adapted from
    # https://superuser.com/questions/1271145/how-do-you-create-a-fake-install-of-a-debian-package-for-use-in-testing/1274900#1274900
    # The `|| :` at the end is to prevent Docker or podman from panicking and
    # exiting.
    && mkdir -p rpi-rootfs/install \
    && mkdir -p rpi-rootfs/dpkg/info \
    && mkdir -p rpi-rootfs/dpkg/updates \
    && touch rpi-rootfs/dpkg/status \
    && PATH=/sbin:/usr/sbin:$PATH fakeroot dpkg --force-architecture \
        --force-depends --force-script-chrootless --log=`pwd`/rpi-rootfs/dpkg.log \
        --root=`pwd`/rpi-rootfs --instdir `pwd`/rpi-rootfs --admindir=`pwd`/rpi-rootfs/dpkg \
        --install *.deb || : \
    && ln -s /opt/rpi-rootfs/usr/lib/arm-linux-gnueabihf /usr/lib/arm-linux-gnueabihf \
    && ln -s /opt/rpi-rootfs/lib/arm-linux-gnueabihf /lib/arm-linux-gnueabihf \
    && rm /opt/*.deb

ENV PKG_CONFIG_PATH="/usr/lib/arm-linux-gnueabihf/pkgconfig/:$PKG_CONFIG_PATH"
